-- 1Rad Hub: Multi-Role Schema Upgrade
-- This script refactors UserHospitalMappings to support multiple roles per user per hospital.

BEGIN TRANSACTION;

-- 1. Create the new Junction Table for Multi-Role Support
CREATE TABLE [dbo].[UserHospitalRoles] (
    [MappingId] UNIQUEIDENTIFIER NOT NULL,
    [RoleId] INT NOT NULL,
    [AssignedAt] DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_UserHospitalRoles] PRIMARY KEY CLUSTERED ([MappingId], [RoleId]),
    CONSTRAINT [FK_UserHospitalRoles_UserHospitalMappings] FOREIGN KEY ([MappingId]) REFERENCES [dbo].[UserHospitalMappings]([MappingId]) ON DELETE CASCADE,
    CONSTRAINT [FK_UserHospitalRoles_Roles] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([RoleId])
);

-- 2. Migrate Existing Data
-- Map current single RoleId to the new junction table
INSERT INTO [dbo].[UserHospitalRoles] ([MappingId], [RoleId], [AssignedAt])
SELECT [MappingId], [RoleId], [AssignedAt]
FROM [dbo].[UserHospitalMappings]
WHERE [RoleId] IS NOT NULL;

-- 3. Cleanup UserHospitalMappings
-- Dynamically find and drop the Foreign Key constraint for RoleId
DECLARE @ConstraintName nvarchar(200)
SELECT @ConstraintName = name
FROM sys.foreign_keys
WHERE parent_object_id = OBJECT_ID('dbo.UserHospitalMappings')
AND referenced_object_id = OBJECT_ID('dbo.Roles');

IF @ConstraintName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE [dbo].[UserHospitalMappings] DROP CONSTRAINT ' + @ConstraintName)
END

-- Drop the column
ALTER TABLE [dbo].[UserHospitalMappings] DROP COLUMN [RoleId];

COMMIT;

