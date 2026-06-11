-- ============================================================
-- DIAGNOSTIC REPORT — appointment-free (study-based) reporting (Phase 2)
-- Run this against your 1RadDb database.
-- Safe to run multiple times — every step is idempotent.
--
-- A DiagnosticReport now belongs to exactly ONE of:
--   • an Appointment   (RIS / RIS+PACS — existing behaviour), OR
--   • an ImagingStudy  (Cloud PACS-only — no visit).
--
-- Changes:
--   1. dbo.DiagnosticReports.AppointmentId  -> made NULLABLE
--   2. dbo.DiagnosticReports.ImagingStudyId -> new nullable FK to ImagingStudies
--   3. FK + filtered UNIQUE index (one report per study)
-- ============================================================

SET NOCOUNT ON;

-- 1. AppointmentId becomes nullable (legacy rows keep their value).
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'DiagnosticReports'
      AND COLUMN_NAME = 'AppointmentId' AND IS_NULLABLE = 'NO'
)
BEGIN
    ALTER TABLE dbo.DiagnosticReports
        ALTER COLUMN AppointmentId UNIQUEIDENTIFIER NULL;
    PRINT '  ~ Made dbo.DiagnosticReports.AppointmentId nullable';
END
ELSE
    PRINT '  = dbo.DiagnosticReports.AppointmentId is already nullable.';
GO

-- 2. ImagingStudyId column.
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'DiagnosticReports'
      AND COLUMN_NAME = 'ImagingStudyId'
)
BEGIN
    ALTER TABLE dbo.DiagnosticReports
        ADD ImagingStudyId UNIQUEIDENTIFIER NULL;
    PRINT '  + Added column dbo.DiagnosticReports.ImagingStudyId';
END
ELSE
    PRINT '  = Column dbo.DiagnosticReports.ImagingStudyId already exists.';
GO

-- 3. FK -> ImagingStudies (NO ACTION: deleting a study is an explicit op).
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DiagnosticReports_ImagingStudies_ImagingStudyId')
BEGIN
    ALTER TABLE dbo.DiagnosticReports
        ADD CONSTRAINT FK_DiagnosticReports_ImagingStudies_ImagingStudyId
        FOREIGN KEY (ImagingStudyId) REFERENCES dbo.ImagingStudies (Id) ON DELETE NO ACTION;
    PRINT '  + Created FK_DiagnosticReports_ImagingStudies_ImagingStudyId';
END
ELSE PRINT '  = FK_DiagnosticReports_ImagingStudies_ImagingStudyId already exists.';
GO

-- 4. One report per study (filtered unique).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_DiagnosticReports_ImagingStudyId' AND object_id = OBJECT_ID('dbo.DiagnosticReports'))
BEGIN
    CREATE UNIQUE INDEX UX_DiagnosticReports_ImagingStudyId ON dbo.DiagnosticReports (ImagingStudyId)
        WHERE ImagingStudyId IS NOT NULL;
    PRINT '  + Created UX_DiagnosticReports_ImagingStudyId';
END
ELSE PRINT '  = UX_DiagnosticReports_ImagingStudyId already exists.';
GO
