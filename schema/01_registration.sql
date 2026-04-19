/* =========================================================
   1Rad / Clinical Command Hub
   Master Create Script (v2.0 - Many-to-Many Roles & Mission Control)
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   1. HospitalGroups
   ========================================================= */
IF OBJECT_ID('dbo.HospitalGroups', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.HospitalGroups
    (
        GroupId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_HospitalGroups PRIMARY KEY
            CONSTRAINT DF_HospitalGroups_GroupId DEFAULT NEWID(),

        GroupName NVARCHAR(255) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,

        CreatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_HospitalGroups_CreatedAt DEFAULT GETUTCDATE()
    );
END
GO

/* =========================================================
   2. Hospitals
   ========================================================= */
IF OBJECT_ID('dbo.Hospitals', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Hospitals
    (
        HospitalId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_Hospitals PRIMARY KEY
            CONSTRAINT DF_Hospitals_HospitalId DEFAULT NEWID(),

        GroupId UNIQUEIDENTIFIER NULL,
        HospitalName NVARCHAR(255) NOT NULL,
        HospitalAddress NVARCHAR(MAX) NOT NULL,
        GSTIN NVARCHAR(15) NULL,
        RegistrationNumber NVARCHAR(100) NULL,
        PAN NVARCHAR(10) NULL,
        NABHNumber NVARCHAR(100) NULL,
        [Status] NVARCHAR(20) NOT NULL
            CONSTRAINT DF_Hospitals_Status DEFAULT 'Active',

        CreatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_Hospitals_CreatedAt DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Hospitals_HospitalGroups
            FOREIGN KEY (GroupId)
            REFERENCES dbo.HospitalGroups(GroupId)
    );
END
GO

/* =========================================================
   3. Users
   ========================================================= */
IF OBJECT_ID('dbo.Users', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users
    (
        UserId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_Users PRIMARY KEY
            CONSTRAINT DF_Users_UserId DEFAULT NEWID(),

        FullName NVARCHAR(255) NOT NULL,
        Email NVARCHAR(255) NOT NULL,
        Mobile NVARCHAR(20) NOT NULL,
        PasswordHash NVARCHAR(MAX) NOT NULL,
        IsVerified BIT NOT NULL
            CONSTRAINT DF_Users_IsVerified DEFAULT 0,
        [Status] NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Users_Status DEFAULT 'Pending',
        Specialization NVARCHAR(500) NULL,
        Degree NVARCHAR(255) NULL,
        LicenseNo NVARCHAR(100) NULL,

        CreatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_Users_CreatedAt DEFAULT GETUTCDATE(),

        CONSTRAINT UQ_Users_Email UNIQUE (Email),
        CONSTRAINT UQ_Users_Mobile UNIQUE (Mobile)
    );
END
GO

/* =========================================================
   4. Roles
   ========================================================= */
IF OBJECT_ID('dbo.Roles', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles
    (
        RoleId INT NOT NULL IDENTITY(1,1)
            CONSTRAINT PK_Roles PRIMARY KEY,

        RoleName NVARCHAR(50) NOT NULL
    );
END
GO

/* =========================================================
   5. UserHospitalMappings (Many-to-Many Bridge)
   ========================================================= */
IF OBJECT_ID('dbo.UserHospitalMappings', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserHospitalMappings
    (
        MappingId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_UserHospitalMappings PRIMARY KEY
            CONSTRAINT DF_UserHospitalMappings_MappingId DEFAULT NEWID(),

        UserId UNIQUEIDENTIFIER NOT NULL,
        HospitalId UNIQUEIDENTIFIER NOT NULL,

        IsDefault BIT NOT NULL
            CONSTRAINT DF_UserHospitalMappings_IsDefault DEFAULT 0,

        AssignedAt DATETIME2 NOT NULL
            CONSTRAINT DF_UserHospitalMappings_AssignedAt DEFAULT GETUTCDATE(),

        CONSTRAINT FK_UserHospitalMappings_Users
            FOREIGN KEY (UserId)
            REFERENCES dbo.Users(UserId),

        CONSTRAINT FK_UserHospitalMappings_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId),

        CONSTRAINT UQ_User_Hospital UNIQUE (UserId, HospitalId)
    );
END
GO
