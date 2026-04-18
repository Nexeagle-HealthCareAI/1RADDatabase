/* =========================================================
   1Rad / Clinical Command Hub
   Rollback Script
   Drops child tables first
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.UserHospitalMappings', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.UserHospitalMappings;
END
GO

IF OBJECT_ID('dbo.OTPVerifications', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.OTPVerifications;
END
GO

IF OBJECT_ID('dbo.Roles', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Roles;
END
GO

IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Users;
END
GO

IF OBJECT_ID('dbo.Hospitals', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Hospitals;
END
GO

IF OBJECT_ID('dbo.HospitalGroups', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.HospitalGroups;
END
GO

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Users]')
      AND name = 'Status'
)
BEGIN
    DECLARE @ConstraintName NVARCHAR(200);

    SELECT @ConstraintName = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c
        ON c.default_object_id = dc.object_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[dbo].[Users]')
      AND c.name = 'Status';

    IF @ConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE [dbo].[Users] DROP CONSTRAINT [' + @ConstraintName + ']');
    END

    ALTER TABLE [dbo].[Users]
    DROP COLUMN [Status];
END
GO