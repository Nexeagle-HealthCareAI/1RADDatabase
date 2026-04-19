/* =========================================================
   1Rad / Clinical Command Hub
   Rollback Script: Mission Control & Security Infrastructure
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   1. Drop Appointments Table (Dependent on Patients)
   ========================================================= */
IF OBJECT_ID('dbo.Appointments', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Appointments;
    PRINT 'Dropped table [dbo].[Appointments].';
END
GO

/* =========================================================
   2. Drop Patients Table
   ========================================================= */
IF OBJECT_ID('dbo.Patients', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Patients;
    PRINT 'Dropped table [dbo].[Patients].';
END
GO

/* =========================================================
   3. Drop Referrers Table
   ========================================================= */
IF OBJECT_ID('dbo.Referrers', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Referrers;
    PRINT 'Dropped table [dbo].[Referrers].';
END
GO

/* =========================================================
   4. Drop Security Infrastructure
   ========================================================= */

IF OBJECT_ID('dbo.RefreshTokens', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.RefreshTokens;
    PRINT 'Dropped table [dbo].[RefreshTokens].';
END
GO

IF OBJECT_ID('dbo.OTPVerifications', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.OTPVerifications;
    PRINT 'Dropped table [dbo].[OTPVerifications].';
END
GO

PRINT 'Rollback of Mission Control infrastructure completed.';
GO
