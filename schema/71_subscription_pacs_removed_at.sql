-- ============================================================
-- SUBSCRIPTION — PACS downgrade lifecycle (Phase 2)
-- Run this against your 1RadDb database.
-- Safe to run multiple times — idempotent.
--
-- Adds dbo.HospitalSubscriptions.PacsRemovedAt: stamped when PACS is removed
-- from a center's Modules. Within the grace window the center keeps read-only
-- access to its studies; after the window an auto-delete job removes them.
-- NULL = PACS active (or never had it).
-- ============================================================

SET NOCOUNT ON;

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'HospitalSubscriptions'
      AND COLUMN_NAME = 'PacsRemovedAt'
)
BEGIN
    ALTER TABLE dbo.HospitalSubscriptions
        ADD PacsRemovedAt DATETIME2 NULL;
    PRINT '  + Added column dbo.HospitalSubscriptions.PacsRemovedAt';
END
ELSE
    PRINT '  = Column dbo.HospitalSubscriptions.PacsRemovedAt already exists.';
GO
