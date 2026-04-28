/* 
  1RAD DATABASE EVOLUTION - SCRIPT 14
  Objective: Relational Field Evolution for Structured Diagnostic Reporting
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON

-- 1. Create the DiagnosticReportFields table to handle dynamic structured fields
-- This replaces the need for packing multiple fields into a single JSON Findings string
IF OBJECT_ID('dbo.DiagnosticReportFields', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DiagnosticReportFields] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        [ReportId] UNIQUEIDENTIFIER NOT NULL,
        [SectionName] NVARCHAR(255) NULL,  -- Grouping (e.g., GALL BLADDER, LIVER)
        [FieldName] NVARCHAR(255) NOT NULL, -- Parameter (e.g., Size, Findings)
        [FieldValue] NVARCHAR(MAX) NOT NULL, -- The clinical observation
        [SortOrder] INT DEFAULT 0,
        [CreatedAt] DATETIME2 DEFAULT GETUTCDATE() NOT NULL,

        CONSTRAINT [FK_DiagnosticReportFields_Report] FOREIGN KEY ([ReportId]) 
            REFERENCES [dbo].[DiagnosticReports] ([Id]) ON DELETE CASCADE
    );

    CREATE INDEX [IX_ReportFields_ReportId] ON [dbo].[DiagnosticReportFields] ([ReportId]);
    CREATE INDEX [IX_ReportFields_FieldName] ON [dbo].[DiagnosticReportFields] ([FieldName]);
    
    PRINT 'SUCCESS: Relational Field Evolution implemented via DiagnosticReportFields';
END
GO

-- 2. Optional: Add a metadata flag to the main table for faster paradigm routing
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[DiagnosticReports]') AND name = 'FieldCount')
BEGIN
    ALTER TABLE [dbo].[DiagnosticReports] 
    ADD [FieldCount] INT DEFAULT 0;
    
    PRINT 'SUCCESS: FieldCount metadata added to DiagnosticReports';
END
GO
