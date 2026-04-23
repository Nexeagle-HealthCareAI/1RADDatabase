/* =========================================================
   1Rad / Diagnostic Acquisition Infrastructure
   DDL Script: Study Assets & Clinical Narratives
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Expansion: Clinical Mission (Appointments)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'TechnicianComments')
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [TechnicianComments] NVARCHAR(MAX) NULL;
    ALTER TABLE [dbo].[Appointments] ADD [TechnicianId] UNIQUEIDENTIFIER NULL;
    ALTER TABLE [dbo].[Appointments] ADD [ScannedAt] DATETIME2 NULL;
END
GO

-- 2. New Table: StudyAssets
IF OBJECT_ID('dbo.StudyAssets', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[StudyAssets] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        [AppointmentId] UNIQUEIDENTIFIER NOT NULL,
        [BlobUrl] NVARCHAR(MAX) NOT NULL,
        [FileName] NVARCHAR(500) NOT NULL,
        [FileType] NVARCHAR(50) NOT NULL, -- zip, dcm, jpg, png
        [TechnicianComments] NVARCHAR(MAX) NULL, -- Optional per-asset comments
        [UploadedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        
        CONSTRAINT [FK_StudyAssets_Appointments] FOREIGN KEY ([AppointmentId]) REFERENCES [dbo].[Appointments] ([AppointmentId]) ON DELETE CASCADE,
        CONSTRAINT [FK_StudyAssets_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId]) ON DELETE NO ACTION
    );
    
    CREATE INDEX [IX_StudyAssets_AppointmentId] ON [dbo].[StudyAssets] ([AppointmentId]);
    CREATE INDEX [IX_StudyAssets_HospitalId] ON [dbo].[StudyAssets] ([HospitalId]);
END
GO
