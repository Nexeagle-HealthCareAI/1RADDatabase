-- 1Rad Hub: Multi-Role Schema Upgrade
-- This script refactors UserHospitalMappings to support multiple roles per user per hospital.
BEGIN TRY
    BEGIN TRANSACTION;

    /* =========================================================
       1. Create UserHospitalRoles only if it does not already exist
       ========================================================= */
    IF OBJECT_ID(N'[dbo].[UserHospitalRoles]', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[UserHospitalRoles] (
            [MappingId] UNIQUEIDENTIFIER NOT NULL,
            [RoleId] INT NOT NULL,
            [AssignedAt] DATETIME NOT NULL 
                CONSTRAINT [DF_UserHospitalRoles_AssignedAt] DEFAULT GETUTCDATE(),

            CONSTRAINT [PK_UserHospitalRoles] 
                PRIMARY KEY CLUSTERED ([MappingId], [RoleId]),

            CONSTRAINT [FK_UserHospitalRoles_UserHospitalMappings] 
                FOREIGN KEY ([MappingId]) 
                REFERENCES [dbo].[UserHospitalMappings]([MappingId]) 
                ON DELETE CASCADE,

            CONSTRAINT [FK_UserHospitalRoles_Roles] 
                FOREIGN KEY ([RoleId]) 
                REFERENCES [dbo].[Roles]([RoleId])
        );
    END

    /* =========================================================
       2. Migrate existing RoleId data only if:
          - source column still exists
          - and row not already migrated
       ========================================================= */
    IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'[dbo].[UserHospitalMappings]')
          AND name = 'RoleId'
    )
    BEGIN
        INSERT INTO [dbo].[UserHospitalRoles] ([MappingId], [RoleId], [AssignedAt])
        SELECT 
            UHM.[MappingId],
            UHM.[RoleId],
            ISNULL(UHM.[AssignedAt], GETUTCDATE())
        FROM [dbo].[UserHospitalMappings] UHM
        WHERE UHM.[RoleId] IS NOT NULL
          AND NOT EXISTS (
                SELECT 1
                FROM [dbo].[UserHospitalRoles] UHR
                WHERE UHR.[MappingId] = UHM.[MappingId]
                  AND UHR.[RoleId] = UHM.[RoleId]
          );
    END

    /* =========================================================
       3. Drop FK and RoleId column only if RoleId still exists
       ========================================================= */
    IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'[dbo].[UserHospitalMappings]')
          AND name = 'RoleId'
    )
    BEGIN
        DECLARE @ConstraintName NVARCHAR(200);

        SELECT TOP 1 @ConstraintName = fk.name
        FROM sys.foreign_keys fk
        INNER JOIN sys.foreign_key_columns fkc
            ON fk.object_id = fkc.constraint_object_id
        INNER JOIN sys.columns c
            ON c.object_id = fkc.parent_object_id
           AND c.column_id = fkc.parent_column_id
        WHERE fk.parent_object_id = OBJECT_ID(N'[dbo].[UserHospitalMappings]')
          AND c.name = 'RoleId';

        IF @ConstraintName IS NOT NULL
        BEGIN
            EXEC(N'ALTER TABLE [dbo].[UserHospitalMappings] DROP CONSTRAINT [' + @ConstraintName + ']');
        END

        ALTER TABLE [dbo].[UserHospitalMappings] DROP COLUMN [RoleId];
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;


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



