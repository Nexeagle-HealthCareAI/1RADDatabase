-- ============================================================
-- STORAGE METERING MIGRATION (Phase 3 of the RIS/PACS SKU split)
-- Run this against your 1RadDb database.
-- Safe to run multiple times — every step is idempotent.
--
-- Adds:
--   1. dbo.StudyAssets.StorageBytes (BIGINT, default 0)
--      Bytes the asset persists in blob storage. Set at upload,
--      recomputed by extraction (original blob + HTJ2K slices).
--      0 on legacy rows = "unmetered history"; metering starts
--      from deployment. A hospital's usage is SUM(StorageBytes).
--   2. dbo.HospitalSubscriptions.IncludedStorageGb (INT, NULL)
--      PACS storage allowance. NULL = unmetered (legacy plans
--      and RIS-only). Over-quota blocks NEW DICOM uploads only —
--      viewing existing studies is never blocked.
-- ============================================================

SET NOCOUNT ON;
PRINT '----------------------------------------------------------';
PRINT ' Starting storage metering migration';
PRINT '----------------------------------------------------------';

/* ============================================================
   1. StudyAssets.StorageBytes
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'StudyAssets'
      AND COLUMN_NAME = 'StorageBytes'
)
BEGIN
    ALTER TABLE dbo.StudyAssets
        ADD [StorageBytes] BIGINT NOT NULL
            CONSTRAINT DF_StudyAssets_StorageBytes DEFAULT 0;
    PRINT '  + Added column dbo.StudyAssets.StorageBytes (default 0)';
END
ELSE
    PRINT '  = Column dbo.StudyAssets.StorageBytes already exists — skipped';

/* ============================================================
   2. HospitalSubscriptions.IncludedStorageGb
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'HospitalSubscriptions'
      AND COLUMN_NAME = 'IncludedStorageGb'
)
BEGIN
    ALTER TABLE dbo.HospitalSubscriptions
        ADD [IncludedStorageGb] INT NULL;
    PRINT '  + Added column dbo.HospitalSubscriptions.IncludedStorageGb (NULL = unmetered)';
END
ELSE
    PRINT '  = Column dbo.HospitalSubscriptions.IncludedStorageGb already exists — skipped';

PRINT '----------------------------------------------------------';
PRINT ' Storage metering migration complete';
PRINT '----------------------------------------------------------';
