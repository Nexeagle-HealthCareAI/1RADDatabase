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