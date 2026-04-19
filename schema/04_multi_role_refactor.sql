-- 1Rad Hub: Multi-Role Schema Upgrade (FIXED)
-- This script refactors UserHospitalMappings to support multiple roles per user per hospital.
-- Refactored to use dynamic SQL to avoid "Invalid column name" compilation errors.

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
        
        -- Performance index for Role-based queries
        CREATE NONCLUSTERED INDEX [IX_UserHospitalRoles_RoleId] 
        ON [dbo].[UserHospitalRoles] ([RoleId]);
        
        PRINT 'Created table [dbo].[UserHospitalRoles].';
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
        -- Using dynamic SQL to avoid compilation error if RoleId is missing from the batch
        EXEC(N'
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
        ');
        PRINT 'Data migration completed.';
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
            PRINT 'Dropped foreign key constraint: ' + @ConstraintName;
        END

        -- Using dynamic SQL for dropping the column to avoid compilation issues
        EXEC(N'ALTER TABLE [dbo].[UserHospitalMappings] DROP COLUMN [RoleId]');
        PRINT 'Dropped column [RoleId] from [UserHospitalMappings].';
    END

    COMMIT TRANSACTION;
    PRINT 'Multi-role migration script executed successfully.';

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
