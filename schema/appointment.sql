-- Patients Table Update/Creation
IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = OBJECT_ID(N'[dbo].[Patients]'))
BEGIN
    CREATE TABLE [dbo].[Patients] (
        [PatientId] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [FullName] NVARCHAR(255) NOT NULL,
        [Mobile] NVARCHAR(20) NULL,
        [Age] NVARCHAR(20) NULL,
        [Gender] NVARCHAR(50) NULL,
        [Village] NVARCHAR(MAX) NULL,
        [District] NVARCHAR(MAX) NULL,
        [Address] NVARCHAR(MAX) NULL,
        [PatientIdentifier] NVARCHAR(50) NOT NULL,
        [SourceOfInfo] NVARCHAR(MAX) NULL,
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT [FK_Patients_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );
END
GO
-- Referrers Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = OBJECT_ID(N'[dbo].[Referrers]'))
BEGIN
    CREATE TABLE [dbo].[Referrers] (
        [ReferrerId] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [Name] NVARCHAR(255) NOT NULL,
        [Contact] NVARCHAR(20) NULL,
        [Address] NVARCHAR(MAX) NULL,
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT [FK_Referrers_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );
END
GO
-- Appointments Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]'))
BEGIN
    CREATE TABLE [dbo].[Appointments] (
        [AppointmentId] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [DisplayId] NVARCHAR(50) NOT NULL,
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
END
GO