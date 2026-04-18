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


-- SQL Migration Script for Hospital Metadata Fields

-- Target Table: dbo.Hospitals
-- Schema: dbo

-- 1. Add RegistrationNumber
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Hospitals]') AND name = 'RegistrationNumber')
BEGIN
    ALTER TABLE [dbo].[Hospitals] ADD [RegistrationNumber] nvarchar(100) NULL;
END
GO

-- 2. Add PAN
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Hospitals]') AND name = 'PAN')
BEGIN
    ALTER TABLE [dbo].[Hospitals] ADD [PAN] nvarchar(10) NULL;
END
GO

-- 3. Add NABHNumber
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Hospitals]') AND name = 'NABHNumber')
BEGIN
    ALTER TABLE [dbo].[Hospitals] ADD [NABHNumber] nvarchar(100) NULL;
END
GO

-- 4. Update GSTIN Constraints (Optional - Ensure MaxLength 15)
-- Note: This depends on existing column state.
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Hospitals]') AND name = 'GSTIN')
BEGIN
    ALTER TABLE [dbo].[Hospitals] ALTER COLUMN [GSTIN] nvarchar(15) NULL;
END
GO



