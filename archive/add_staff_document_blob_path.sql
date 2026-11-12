-- ============================================================
-- STAFF DOCUMENT BLOB PATH + CONTAINER COLUMNS
-- Run this against your 1RadDb database.
-- Safe to run multiple times — every step is idempotent.
--
-- Adds:
--   1. dbo.StaffDocuments.BlobPath      (relative path within the container —
--                                        used by the API to delete reliably)
--   2. dbo.StaffDocuments.BlobContainer (which Azure container the blob lives in)
-- ============================================================

SET NOCOUNT ON;

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'StaffDocuments'
      AND COLUMN_NAME = 'BlobPath'
)
BEGIN
    ALTER TABLE dbo.StaffDocuments
        ADD BlobPath NVARCHAR(500) NULL;
    PRINT '  + Added column dbo.StaffDocuments.BlobPath';
END
ELSE
    PRINT '  = Column dbo.StaffDocuments.BlobPath already exists.';
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'StaffDocuments'
      AND COLUMN_NAME = 'BlobContainer'
)
BEGIN
    ALTER TABLE dbo.StaffDocuments
        ADD BlobContainer NVARCHAR(100) NULL;
    PRINT '  + Added column dbo.StaffDocuments.BlobContainer';
END
ELSE
    PRINT '  = Column dbo.StaffDocuments.BlobContainer already exists.';
GO
