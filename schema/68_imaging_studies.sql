-- ============================================================
-- IMAGING STUDIES MIGRATION (Phase 1 of the RIS/PACS SKU split)
-- Run this against your 1RadDb database.
-- Safe to run multiple times — every step is idempotent.
--
-- Introduces the ImagingStudy aggregate: one row per DICOM study
-- the cloud PACS holds, with the Appointment link now OPTIONAL.
--
--   1. Creates dbo.ImagingStudies
--   2. dbo.StudyAssets:       AppointmentId -> NULLable,
--                             + ImagingStudyId (FK) + index
--   3. dbo.StudySliceIndexes: AppointmentId -> NULLable
--   4. Backfill: one ImagingStudy per existing DICOM-bearing
--      StudyAsset (zip / instances / dcm), Id = the asset's Id so
--      the correlation is a single pass. Document attachments
--      (pdf / jpg / png) get NO study row.
--
-- Existing RIS+PACS behaviour is unchanged: every current flow
-- still sets AppointmentId. PACS-only ingestion (Phase 2) will
-- create studies with AppointmentId = NULL.
-- ============================================================

SET NOCOUNT ON;
PRINT '----------------------------------------------------------';
PRINT ' Starting imaging studies migration';
PRINT '----------------------------------------------------------';

/* ============================================================
   1. dbo.ImagingStudies
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'ImagingStudies'
)
BEGIN
    CREATE TABLE dbo.ImagingStudies (
        [Id]                   UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_ImagingStudies PRIMARY KEY,
        [HospitalId]           UNIQUEIDENTIFIER NOT NULL,
        [StudyInstanceUID]     NVARCHAR(128)    NULL,
        [PatientId]            UNIQUEIDENTIFIER NULL,
        [PatientName]          NVARCHAR(255)    NULL,
        [DicomPatientId]       NVARCHAR(128)    NULL,
        [Modality]             NVARCHAR(32)     NULL,
        [StudyDate]            DATETIME2        NULL,
        [StudyDescription]     NVARCHAR(255)    NULL,
        [Status]               NVARCHAR(20)     NOT NULL
            CONSTRAINT DF_ImagingStudies_Status DEFAULT 'Received',
        [Source]               NVARCHAR(32)     NULL,
        [AppointmentId]        UNIQUEIDENTIFIER NULL,
        [AppointmentServiceId] UNIQUEIDENTIFIER NULL,
        [CreatedAt]            DATETIME2        NOT NULL
            CONSTRAINT DF_ImagingStudies_CreatedAt DEFAULT SYSUTCDATETIME(),
        [ReadyAt]              DATETIME2        NULL,

        CONSTRAINT FK_ImagingStudies_Appointments FOREIGN KEY ([AppointmentId])
            REFERENCES dbo.Appointments ([AppointmentId]) ON DELETE SET NULL,
        CONSTRAINT FK_ImagingStudies_Patients FOREIGN KEY ([PatientId])
            REFERENCES dbo.Patients ([PatientId])
    );

    -- DICOM identity: unique per tenant when known (legacy rows stay NULL).
    CREATE UNIQUE INDEX UX_ImagingStudies_Hospital_StudyUID
        ON dbo.ImagingStudies ([HospitalId], [StudyInstanceUID])
        WHERE [StudyInstanceUID] IS NOT NULL;

    CREATE INDEX IX_ImagingStudies_AppointmentId
        ON dbo.ImagingStudies ([AppointmentId])
        WHERE [AppointmentId] IS NOT NULL;

    -- Study-browser worklist: newest studies for a hospital.
    CREATE INDEX IX_ImagingStudies_Hospital_CreatedAt
        ON dbo.ImagingStudies ([HospitalId], [CreatedAt]);

    PRINT '  + Created table dbo.ImagingStudies (+ 3 indexes)';
END
ELSE
    PRINT '  = Table dbo.ImagingStudies already exists — skipped';

/* ============================================================
   2. dbo.StudyAssets — AppointmentId NULLable + ImagingStudyId
   ============================================================ */

-- 2a. AppointmentId -> NULL. ALTER COLUMN is blocked by any index/FK
--     on the column, so drop them dynamically first and recreate after.
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'StudyAssets'
      AND COLUMN_NAME = 'AppointmentId' AND IS_NULLABLE = 'NO'
)
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'';

    -- Drop FKs that reference the column (from StudyAssets side).
    SELECT @sql = @sql + N'ALTER TABLE dbo.StudyAssets DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';'
    FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
    JOIN sys.columns c ON c.object_id = fkc.parent_object_id AND c.column_id = fkc.parent_column_id
    WHERE fk.parent_object_id = OBJECT_ID('dbo.StudyAssets') AND c.name = 'AppointmentId';

    -- Drop indexes that include the column.
    SELECT @sql = @sql + N'DROP INDEX ' + QUOTENAME(i.name) + N' ON dbo.StudyAssets;'
    FROM sys.indexes i
    JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = OBJECT_ID('dbo.StudyAssets') AND c.name = 'AppointmentId'
      AND i.is_primary_key = 0 AND i.type > 0;

    EXEC sp_executesql @sql;

    ALTER TABLE dbo.StudyAssets ALTER COLUMN [AppointmentId] UNIQUEIDENTIFIER NULL;

    -- Recreate the FK (cascade, as before) and a plain index.
    ALTER TABLE dbo.StudyAssets WITH CHECK
        ADD CONSTRAINT FK_StudyAssets_Appointments FOREIGN KEY ([AppointmentId])
        REFERENCES dbo.Appointments ([AppointmentId]) ON DELETE CASCADE;
    CREATE INDEX IX_StudyAssets_AppointmentId
        ON dbo.StudyAssets ([AppointmentId]) WHERE [AppointmentId] IS NOT NULL;

    PRINT '  + dbo.StudyAssets.AppointmentId is now NULLable (FK + index recreated)';
END
ELSE
    PRINT '  = dbo.StudyAssets.AppointmentId already NULLable — skipped';

-- 2b. ImagingStudyId column + FK + filtered index.
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'StudyAssets'
      AND COLUMN_NAME = 'ImagingStudyId'
)
BEGIN
    ALTER TABLE dbo.StudyAssets ADD [ImagingStudyId] UNIQUEIDENTIFIER NULL;
    PRINT '  + Added column dbo.StudyAssets.ImagingStudyId';
END
ELSE
    PRINT '  = Column dbo.StudyAssets.ImagingStudyId already exists — skipped';

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_StudyAssets_ImagingStudies'
)
BEGIN
    ALTER TABLE dbo.StudyAssets WITH CHECK
        ADD CONSTRAINT FK_StudyAssets_ImagingStudies FOREIGN KEY ([ImagingStudyId])
        REFERENCES dbo.ImagingStudies ([Id]);   -- NO ACTION: study deletion is explicit
    PRINT '  + Added FK_StudyAssets_ImagingStudies';
END
ELSE
    PRINT '  = FK_StudyAssets_ImagingStudies already exists — skipped';

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_StudyAssets_ImagingStudyId' AND object_id = OBJECT_ID('dbo.StudyAssets')
)
BEGIN
    CREATE INDEX IX_StudyAssets_ImagingStudyId
        ON dbo.StudyAssets ([ImagingStudyId]) WHERE [ImagingStudyId] IS NOT NULL;
    PRINT '  + Added IX_StudyAssets_ImagingStudyId';
END
ELSE
    PRINT '  = IX_StudyAssets_ImagingStudyId already exists — skipped';

/* ============================================================
   3. dbo.StudySliceIndexes — AppointmentId NULLable
   ============================================================ */
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'StudySliceIndexes'
      AND COLUMN_NAME = 'AppointmentId' AND IS_NULLABLE = 'NO'
)
BEGIN
    DECLARE @sql2 NVARCHAR(MAX) = N'';

    SELECT @sql2 = @sql2 + N'ALTER TABLE dbo.StudySliceIndexes DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';'
    FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
    JOIN sys.columns c ON c.object_id = fkc.parent_object_id AND c.column_id = fkc.parent_column_id
    WHERE fk.parent_object_id = OBJECT_ID('dbo.StudySliceIndexes') AND c.name = 'AppointmentId';

    SELECT @sql2 = @sql2 + N'DROP INDEX ' + QUOTENAME(i.name) + N' ON dbo.StudySliceIndexes;'
    FROM sys.indexes i
    JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = OBJECT_ID('dbo.StudySliceIndexes') AND c.name = 'AppointmentId'
      AND i.is_primary_key = 0 AND i.type > 0;

    EXEC sp_executesql @sql2;

    ALTER TABLE dbo.StudySliceIndexes ALTER COLUMN [AppointmentId] UNIQUEIDENTIFIER NULL;

    CREATE INDEX IX_StudySliceIndexes_AppointmentId
        ON dbo.StudySliceIndexes ([AppointmentId]) WHERE [AppointmentId] IS NOT NULL;

    PRINT '  + dbo.StudySliceIndexes.AppointmentId is now NULLable (index recreated)';
END
ELSE
    PRINT '  = dbo.StudySliceIndexes.AppointmentId already NULLable — skipped';

/* ============================================================
   4. Backfill — one ImagingStudy per DICOM-bearing StudyAsset.
      Id = the asset's Id (GUIDs, no collision risk) so linking
      back is a single deterministic pass. Re-runnable.
   ============================================================ */
INSERT INTO dbo.ImagingStudies
    ([Id], [HospitalId], [StudyInstanceUID], [PatientId], [PatientName],
     [Modality], [StudyDate], [Status], [Source],
     [AppointmentId], [AppointmentServiceId], [CreatedAt], [ReadyAt])
SELECT
    sa.[Id],
    sa.[HospitalId],
    NULL,                          -- UID unknown for legacy uploads
    a.[PatientId],
    a.[PatientName],
    a.[Modality],
    a.[DateTime],
    CASE
        WHEN sa.[ExtractionStatus] = 'Extracted' THEN 'Ready'
        WHEN sa.[ExtractionStatus] = 'Failed'    THEN 'Failed'
        WHEN sa.[FileType] IN ('dcm', 'dicom')   THEN 'Ready'   -- directly viewable
        ELSE 'Received'
    END,
    'legacy-backfill',
    sa.[AppointmentId],
    sa.[AppointmentServiceId],
    sa.[UploadedAt],
    sa.[ExtractionCompletedAt]
FROM dbo.StudyAssets sa
LEFT JOIN dbo.Appointments a ON a.[AppointmentId] = sa.[AppointmentId]
WHERE LOWER(sa.[FileType]) IN ('zip', 'instances', 'dcm', 'dicom')
  AND sa.[ImagingStudyId] IS NULL
  AND NOT EXISTS (SELECT 1 FROM dbo.ImagingStudies s WHERE s.[Id] = sa.[Id]);

PRINT '  + Backfilled ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' ImagingStudies rows';

UPDATE sa
SET sa.[ImagingStudyId] = sa.[Id]
FROM dbo.StudyAssets sa
WHERE LOWER(sa.[FileType]) IN ('zip', 'instances', 'dcm', 'dicom')
  AND sa.[ImagingStudyId] IS NULL
  AND EXISTS (SELECT 1 FROM dbo.ImagingStudies s WHERE s.[Id] = sa.[Id]);

PRINT '  + Linked ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' StudyAssets to their ImagingStudy';

PRINT '----------------------------------------------------------';
PRINT ' Imaging studies migration complete';
PRINT '----------------------------------------------------------';
