/* =========================================================
   Migration: Drop BoardAccessUserId from StaffMembers
   
   BoardAccess feature removed — StaffMembers no longer
   links to a board User account.
   ========================================================= */

-- Drop FK first, then the column.
IF EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_StaffMembers_BoardUser'
      AND parent_object_id = OBJECT_ID('dbo.StaffMembers')
)
BEGIN
    ALTER TABLE dbo.StaffMembers DROP CONSTRAINT FK_StaffMembers_BoardUser;
    PRINT 'Dropped constraint FK_StaffMembers_BoardUser';
END
ELSE
    PRINT 'Constraint FK_StaffMembers_BoardUser not found — skipped.';
GO

IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.StaffMembers')
      AND name = 'BoardAccessUserId'
)
BEGIN
    ALTER TABLE dbo.StaffMembers DROP COLUMN BoardAccessUserId;
    PRINT 'Dropped column BoardAccessUserId from dbo.StaffMembers';
END
ELSE
    PRINT 'Column BoardAccessUserId not found — skipped.';
GO
