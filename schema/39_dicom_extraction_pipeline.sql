-- =========================================================================================
-- MIGRATION: 39_dicom_extraction_pipeline.sql
-- DESCRIPTION: Server-side DICOM ZIP extraction pipeline (DICOM viewer Option C).
--              Adds extraction tracking columns to StudyAssets and creates the
--              StudySliceIndexes table that maps each extracted DICOM slice to
--              its public blob URL. The viewer reads StudySliceIndexes via
--              GET /api/v1/Study/{appointmentId}/manifest to load slices
--              directly without downloading and unzipping the original ZIP
--              client-side.
-- =========================================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;
GO

-- ─── 1. StudyAssets — extraction tracking columns ─────────────────────────────────────
-- ExtractionStatus state machine:
--   NULL           — legacy row, never enqueued. Backfill job picks these up.
--   'Queued'       — accepted by /upload-complete, sitting in the in-process queue.
--   'Running'      — DicomExtractionWorker is currently extracting.
--   'Extracted'    — slice index populated; viewer uses the manifest path.
--   'Failed'       — extraction crashed; ExtractionError carries the message.
--   'NotApplicable'— non-ZIP attachments (single .dcm / .jpg / .png) skip extraction.

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE Name = N'ExtractionStatus'
      AND Object_ID = Object_ID(N'dbo.StudyAssets')
)
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionStatus] NVARCHAR(20) NULL;
    PRINT 'Added ExtractionStatus column to StudyAssets.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE Name = N'ExtractionStartedAt'
      AND Object_ID = Object_ID(N'dbo.StudyAssets')
)
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionStartedAt] DATETIME2 NULL;
    PRINT 'Added ExtractionStartedAt column to StudyAssets.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE Name = N'ExtractionCompletedAt'
      AND Object_ID = Object_ID(N'dbo.StudyAssets')
)
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionCompletedAt] DATETIME2 NULL;
    PRINT 'Added ExtractionCompletedAt column to StudyAssets.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE Name = N'ExtractionError'
      AND Object_ID = Object_ID(N'dbo.StudyAssets')
)
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionError] NVARCHAR(2000) NULL;
    PRINT 'Added ExtractionError column to StudyAssets.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE Name = N'ExtractionSliceCount'
      AND Object_ID = Object_ID(N'dbo.StudyAssets')
)
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionSliceCount] INT NOT NULL
        CONSTRAINT [DF_StudyAssets_ExtractionSliceCount] DEFAULT 0;
    PRINT 'Added ExtractionSliceCount column to StudyAssets.';
END
GO

-- Filtered index — the extraction worker's stale-asset sweep on startup
-- walks rows with non-null ExtractionStatus, so filter on that.
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE Name = N'IX_StudyAssets_ExtractionStatus'
      AND Object_ID = Object_ID(N'dbo.StudyAssets')
)
BEGIN
    CREATE INDEX [IX_StudyAssets_ExtractionStatus]
        ON [dbo].[StudyAssets] ([ExtractionStatus])
        WHERE [ExtractionStatus] IS NOT NULL;
    PRINT 'Created index IX_StudyAssets_ExtractionStatus.';
END
GO


-- ─── 2. StudySliceIndexes — one row per extracted DICOM slice ─────────────────────────
-- Populated by DicomExtractionService after the ZIP is unzipped server-side.
-- The manifest endpoint groups these by SeriesUID and returns slice URLs to
-- the viewer, which loads each via Cornerstone's wadouri loader.

IF OBJECT_ID(N'dbo.StudySliceIndexes', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[StudySliceIndexes] (
        [SliceId]            UNIQUEIDENTIFIER NOT NULL CONSTRAINT [PK_StudySliceIndexes] PRIMARY KEY DEFAULT NEWID(),
        [AssetId]            UNIQUEIDENTIFIER NOT NULL,
        [AppointmentId]      UNIQUEIDENTIFIER NOT NULL,
        [HospitalId]         UNIQUEIDENTIFIER NOT NULL,
        [SeriesUID]          NVARCHAR(128)    NOT NULL,  -- DICOM tag (0020,000E)
        [SopInstanceUID]     NVARCHAR(128)    NOT NULL,  -- DICOM tag (0008,0018)
        [InstanceNumber]     INT              NULL,      -- DICOM tag (0020,0013)
        [SeriesDescription]  NVARCHAR(200)    NULL,      -- DICOM tag (0008,103E)
        [Modality]           NVARCHAR(16)     NULL,      -- DICOM tag (0008,0060)
        [BlobUrl]            NVARCHAR(700)    NOT NULL,  -- public HTTPS URL Cornerstone fetches
        [BlobPath]           NVARCHAR(700)    NOT NULL,  -- container-relative path (for cleanup)
        [ThumbnailUrl]       NVARCHAR(700)    NULL,      -- per-series JPEG (only on first slice)
        [MetadataJson]       NVARCHAR(MAX)    NULL,      -- viewer-relevant tags (WC/WW, pixel spacing, etc.)
        [ExtractedAt]        DATETIME2        NOT NULL CONSTRAINT [DF_StudySliceIndexes_ExtractedAt] DEFAULT GETUTCDATE(),

        CONSTRAINT [FK_StudySliceIndexes_StudyAssets]
            FOREIGN KEY ([AssetId]) REFERENCES [dbo].[StudyAssets] ([Id]) ON DELETE CASCADE
    );

    -- Primary read path: manifest endpoint groups by AssetId + SeriesUID, ordered by InstanceNumber.
    CREATE INDEX [IX_StudySliceIndexes_AssetSeriesInstance]
        ON [dbo].[StudySliceIndexes] ([AssetId], [SeriesUID], [InstanceNumber]);

    -- Tenant lookups (audit / reporting / per-hospital slice counts).
    CREATE INDEX [IX_StudySliceIndexes_AppointmentId]
        ON [dbo].[StudySliceIndexes] ([AppointmentId]);
    CREATE INDEX [IX_StudySliceIndexes_HospitalId]
        ON [dbo].[StudySliceIndexes] ([HospitalId]);

    PRINT 'Created table StudySliceIndexes with indexes.';
END
ELSE
BEGIN
    PRINT 'Table StudySliceIndexes already exists — skipping create.';
END
GO

COMMIT TRANSACTION;
GO

PRINT '✅ Migration 39_dicom_extraction_pipeline.sql completed.';
GO
