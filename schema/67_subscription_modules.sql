-- ============================================================
-- SUBSCRIPTION MODULES MIGRATION (product SKUs: RIS / PACS)
-- Run this against your 1RadDb database.
-- Safe to run multiple times — every step is idempotent.
--
-- Adds:
--   1. dbo.HospitalSubscriptions.Modules (comma list, e.g. 'RIS,PACS')
--
-- A center's subscription now records WHICH product modules it
-- bought: 'RIS' (worklist/billing/referrals, PDF-JPG attachments
-- only), 'PACS' (DICOM upload/extraction/viewer), or 'RIS,PACS'.
-- Reporting is included in every SKU and is not a module.
-- Existing rows are backfilled to the full product so nothing
-- changes for current customers.
-- ============================================================

SET NOCOUNT ON;
PRINT '----------------------------------------------------------';
PRINT ' Starting subscription modules migration';
PRINT '----------------------------------------------------------';

/* ============================================================
   1. HospitalSubscriptions.Modules — 'RIS,PACS' default
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'HospitalSubscriptions'
      AND COLUMN_NAME = 'Modules'
)
BEGIN
    ALTER TABLE dbo.HospitalSubscriptions
        ADD [Modules] NVARCHAR(200) NOT NULL
            CONSTRAINT DF_HospitalSubscriptions_Modules DEFAULT 'RIS,PACS';
    PRINT '  + Added column dbo.HospitalSubscriptions.Modules (default ''RIS,PACS'')';
END
ELSE
    PRINT '  = Column dbo.HospitalSubscriptions.Modules already exists — skipped';

/* ============================================================
   2. Backfill safety net — any row that somehow has an empty
      value gets the full product (matches pre-module behaviour)
   ============================================================ */
UPDATE dbo.HospitalSubscriptions
SET [Modules] = 'RIS,PACS'
WHERE LTRIM(RTRIM(ISNULL([Modules], ''))) = '';

PRINT '----------------------------------------------------------';
PRINT ' Subscription modules migration complete';
PRINT '----------------------------------------------------------';
