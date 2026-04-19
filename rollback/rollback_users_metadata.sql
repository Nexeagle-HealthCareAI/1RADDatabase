/* =========================================================
   1Rad / Clinical Command Hub
   Rollback Script: Registration & Hospital Metadata Reversion
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   1. Users Table Rolback
   ========================================================= */

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'Specialization')
BEGIN
    ALTER TABLE [dbo].[Users] 
    DROP COLUMN [Specialization], [Degree], [LicenseNo];
    PRINT 'Dropped clinical columns from [dbo].[Users].';
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'IsVerified')
BEGIN
    -- Need to drop default constraint first
    DECLARE @UserVerifiedConstraint NVARCHAR(200);
    SELECT @UserVerifiedConstraint = dc.name FROM sys.default_constraints dc 
    INNER JOIN sys.columns c ON c.default_object_id = dc.object_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[dbo].[Users]') AND c.name = 'IsVerified';

    IF @UserVerifiedConstraint IS NOT NULL
        EXEC('ALTER TABLE [dbo].[Users] DROP CONSTRAINT [' + @UserVerifiedConstraint + ']');

    ALTER TABLE [dbo].[Users] DROP COLUMN [IsVerified];
    PRINT 'Dropped column [IsVerified] from [dbo].[Users].';
END
GO

/* =========================================================
   2. Hospitals Table Rollback
   ========================================================= */

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Hospitals]') AND name = 'RegistrationNumber')
BEGIN
    ALTER TABLE [dbo].[Hospitals] DROP COLUMN [RegistrationNumber];
    PRINT 'Dropped column [RegistrationNumber] from [dbo].[Hospitals].';
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Hospitals]') AND name = 'PAN')
BEGIN
    ALTER TABLE [dbo].[Hospitals] DROP COLUMN [PAN];
    PRINT 'Dropped column [PAN] from [dbo].[Hospitals].';
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Hospitals]') AND name = 'NABHNumber')
BEGIN
    ALTER TABLE [dbo].[Hospitals] DROP COLUMN [NABHNumber];
    PRINT 'Dropped column [NABHNumber] from [dbo].[Hospitals].';
END
GO

PRINT 'Rollback of Hospital & User metadata completed.';
GO
