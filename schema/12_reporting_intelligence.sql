/* =========================================================
   1Rad / Clinical Reporting Intelligence
   DDL Script: Structured Templates, Keywords & Diagnostic Reports
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Table: ReportTemplates
IF OBJECT_ID('dbo.ReportTemplates', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[ReportTemplates] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        [Name] NVARCHAR(255) NOT NULL,
        [Modality] NVARCHAR(50) NOT NULL,
        [IsStructured] BIT DEFAULT 0 NOT NULL,
        [Content] NVARCHAR(MAX) NOT NULL, -- JSON structure or Narrative Text
        [DoctorId] UNIQUEIDENTIFIER NULL,
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME2 DEFAULT GETUTCDATE() NOT NULL,
        
        CONSTRAINT [FK_ReportTemplates_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );
    CREATE INDEX [IX_ReportTemplates_HospitalId] ON [dbo].[ReportTemplates] ([HospitalId]);
    CREATE INDEX [IX_ReportTemplates_Modality] ON [dbo].[ReportTemplates] ([Modality]);
END
GO

-- 2. Table: ReportingKeywords
IF OBJECT_ID('dbo.ReportingKeywords', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[ReportingKeywords] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        [Trigger] NVARCHAR(50) NOT NULL,
        [ReplacementText] NVARCHAR(MAX) NOT NULL,
        [DoctorId] UNIQUEIDENTIFIER NOT NULL,
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME2 DEFAULT GETUTCDATE() NOT NULL,
        
        CONSTRAINT [FK_ReportingKeywords_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId]),
        CONSTRAINT [UQ_ReportingKeywords_Doctor_Trigger] UNIQUE ([DoctorId], [Trigger])
    );
END
GO

-- 3. Table: DiagnosticReports
IF OBJECT_ID('dbo.DiagnosticReports', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DiagnosticReports] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        [AppointmentId] UNIQUEIDENTIFIER NOT NULL,
        [DoctorId] UNIQUEIDENTIFIER NOT NULL,
        [TemplateId] UNIQUEIDENTIFIER NULL,
        [Findings] NVARCHAR(MAX) NOT NULL,
        [Impression] NVARCHAR(MAX) NOT NULL,
        [Advice] NVARCHAR(MAX) NULL,
        [IsFinalized] BIT DEFAULT 0 NOT NULL,
        [FinalizedAt] DATETIME2 NULL,
        [ReportPdfUrl] NVARCHAR(MAX) NULL,
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME2 DEFAULT GETUTCDATE() NOT NULL,
        
        CONSTRAINT [FK_DiagnosticReports_Appointments] FOREIGN KEY ([AppointmentId]) REFERENCES [dbo].[Appointments] ([AppointmentId]) ON DELETE CASCADE,
        CONSTRAINT [FK_DiagnosticReports_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );
    CREATE INDEX [IX_DiagnosticReports_AppointmentId] ON [dbo].[DiagnosticReports] ([AppointmentId]);
END
GO
