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
-- Remove the single RoleId column (only after verification)
-- Note: We keep the Unique Index on (UserId, HospitalId) to ensure one mapping entry per relationship.
ALTER TABLE [dbo].[UserHospitalMappings] DROP CONSTRAINT [FK_UserHospitalMappings_Roles_RoleId];
ALTER TABLE [dbo].[UserHospitalMappings] DROP COLUMN [RoleId];

COMMIT;

