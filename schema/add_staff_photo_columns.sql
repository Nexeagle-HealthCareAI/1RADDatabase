-- ============================================================
-- STAFF PHOTO COLUMNS
-- Run this against your 1RadDb database.
-- Safe to run multiple times — every step is idempotent.
--
-- Adds:
--   1. dbo.StaffMembers.PhotoUrl   (public HTTPS URL of the staff photo blob)
--   2. dbo.StaffMembers.PhotoPath  (relative path inside the container — used for reliable deletes)
-- ============================================================

SET NOCOUNT ON;

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'StaffMembers'
      AND COLUMN_NAME = 'PhotoUrl'
)
BEGIN
    ALTER TABLE dbo.StaffMembers
        ADD PhotoUrl NVARCHAR(2000) NULL;
    PRINT '  + Added column dbo.StaffMembers.PhotoUrl';
END
ELSE
    PRINT '  = Column dbo.StaffMembers.PhotoUrl already exists.';
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'StaffMembers'
      AND COLUMN_NAME = 'PhotoPath'
)
BEGIN
    ALTER TABLE dbo.StaffMembers
        ADD PhotoPath NVARCHAR(500) NULL;
    PRINT '  + Added column dbo.StaffMembers.PhotoPath';
END
ELSE
    PRINT '  = Column dbo.StaffMembers.PhotoPath already exists.';
GO
