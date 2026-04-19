/* =========================================================
   1Rad / Clinical Command Hub
   Rollback Script: Multi-Role Schema Reversion
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    /* =========================================================
       1. Re-add RoleId to UserHospitalMappings
       ========================================================= */
    IF NOT EXISTS (
        SELECT 1 FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'[dbo].[UserHospitalMappings]') 
        AND name = 'RoleId'
    )
    BEGIN
        ALTER TABLE [dbo].[UserHospitalMappings] ADD [RoleId] INT NULL;
        PRINT 'Re-added column [RoleId] to [UserHospitalMappings].';

        -- Restore Foreign Key
        ALTER TABLE [dbo].[UserHospitalMappings] 
        ADD CONSTRAINT [FK_UserHospitalMappings_Roles] 
        FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([RoleId]);
        PRINT 'Restored foreign key [FK_UserHospitalMappings_Roles].';
    END

    /* =========================================================
       2. Data Migration: Pull first role from UserHospitalRoles
       ========================================================= */
    IF OBJECT_ID(N'[dbo].[UserHospitalRoles]', N'U') IS NOT NULL
    BEGIN
        EXEC(N'
            UPDATE UHM
            SET UHM.[RoleId] = (
                SELECT TOP 1 UHR.[RoleId] 
                FROM [dbo].[UserHospitalRoles] UHR 
                WHERE UHR.[MappingId] = UHM.[MappingId]
                ORDER BY UHR.[AssignedAt] ASC
            )
            FROM [dbo].[UserHospitalMappings] UHM
            WHERE UHM.[RoleId] IS NULL;
        ');
        PRINT 'Re-migrated role data back to [UserHospitalMappings].';
    END

    /* =========================================================
       3. Drop UserHospitalRoles table
       ========================================================= */
    IF OBJECT_ID(N'[dbo].[UserHospitalRoles]', N'U') IS NOT NULL
    BEGIN
        DROP TABLE [dbo].[UserHospitalRoles];
        PRINT 'Dropped table [dbo].[UserHospitalRoles].';
    END

    COMMIT TRANSACTION;
    PRINT 'Multi-role rollback executed successfully.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
        
    THROW;
END CATCH;
GO
