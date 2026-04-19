/* =========================================================
   1Rad / Clinical Command Hub
   DDL Script: Mission Control & Security Infrastructure
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   1. Patients Table
   ========================================================= */
IF OBJECT_ID('dbo.Patients', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Patients (
        [PatientId] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY CONSTRAINT [DF_Patients_PatientId] DEFAULT NEWID(),
        [FullName] NVARCHAR(255) NOT NULL,
        [Mobile] NVARCHAR(20) NULL,
        [Age] NVARCHAR(20) NULL,
        [Gender] NVARCHAR(50) NULL,
        [Village] NVARCHAR(MAX) NULL,
        [District] NVARCHAR(MAX) NULL,
        [Address] NVARCHAR(MAX) NULL,
        [PatientIdentifier] NVARCHAR(50) NOT NULL, -- PTIDXXXXXXXX format
        [SourceOfInfo] NVARCHAR(MAX) NULL,
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT [FK_Patients_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );
    CREATE INDEX [IX_Patients_Mobile] ON [dbo].[Patients] ([Mobile]);
    CREATE INDEX [IX_Patients_HospitalId] ON [dbo].[Patients] ([HospitalId]);
END
GO

/* =========================================================
   2. Referrers Table
   ========================================================= */
IF OBJECT_ID('dbo.Referrers', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Referrers (
        [ReferrerId] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY CONSTRAINT [DF_Referrers_ReferrerId] DEFAULT NEWID(),
        [Name] NVARCHAR(255) NOT NULL,
        [Contact] NVARCHAR(20) NULL,
        [Address] NVARCHAR(MAX) NULL,
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT [FK_Referrers_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );
END
GO

/* =========================================================
   3. Appointments Table
   ========================================================= */
IF OBJECT_ID('dbo.Appointments', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Appointments (
        [AppointmentId] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY CONSTRAINT [DF_Appointments_AppointmentId] DEFAULT NEWID(),
        [DisplayId] NVARCHAR(50) NOT NULL, -- APP-XXX
        [PatientId] UNIQUEIDENTIFIER NOT NULL,
        [PatientName] NVARCHAR(255) NOT NULL,
        [Mobile] NVARCHAR(20) NULL,
        [Service] NVARCHAR(255) NOT NULL,
        [Modality] NVARCHAR(50) NOT NULL,
        [DateTime] DATETIME NOT NULL,
        [Type] NVARCHAR(50) NOT NULL,
        [Doctor] NVARCHAR(255) NULL,
        [Status] NVARCHAR(50) NOT NULL,
        [ReferredBy] NVARCHAR(255) NULL,
        [ReferredContact] NVARCHAR(50) NULL,
        [Notes] NVARCHAR(MAX) NULL,
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT [FK_Appointments_Patients] FOREIGN KEY ([PatientId]) REFERENCES [dbo].[Patients] ([PatientId]),
        CONSTRAINT [FK_Appointments_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );
    CREATE INDEX [IX_Appointments_Status] ON [dbo].[Appointments] ([Status]);
    CREATE INDEX [IX_Appointments_HospitalId] ON [dbo].[Appointments] ([HospitalId]);
END
GO

/* =========================================================
   4. Security Infrastructure (OTP & Refresh Tokens)
   ========================================================= */

-- RefreshTokens Table
IF OBJECT_ID('dbo.RefreshTokens', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RefreshTokens (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY CONSTRAINT [DF_RefreshTokens_Id] DEFAULT NEWID(),
        [UserId] UNIQUEIDENTIFIER NOT NULL,
        [Token] NVARCHAR(500) NOT NULL,
        [ExpiresAt] DATETIME NOT NULL,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        [CreatedByIp] NVARCHAR(100) NULL,
        [RevokedAt] DATETIME NULL,
        [RevokedByIp] NVARCHAR(100) NULL,
        [ReplacedByToken] NVARCHAR(500) NULL,
        CONSTRAINT [FK_RefreshTokens_Users] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId])
    );
END
GO

-- OTPVerifications Table
IF OBJECT_ID('dbo.OTPVerifications', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.OTPVerifications (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY CONSTRAINT [DF_OTPVerifications_Id] DEFAULT NEWID(),
        [Identifier] NVARCHAR(100) NOT NULL,
        [CodeHash] NVARCHAR(MAX) NOT NULL,
        [ExpiresAt] DATETIME NOT NULL,
        [IsUsed] BIT DEFAULT 0 NOT NULL,
        [Purpose] NVARCHAR(MAX) NULL,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL
    );
END
GO
