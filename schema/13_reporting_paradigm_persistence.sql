/* 
  1RAD DATABASE EVOLUTION - SCRIPT 13
  Objective: Implement Persistent Reporting Paradigms (Structured vs. Narrative)
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Update DiagnosticReports table to track report methodology
-- This enables the system to remember which editor was used for each case
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[DiagnosticReports]') AND name = 'ReportingMode')
BEGIN
    ALTER TABLE [dbo].[DiagnosticReports] 
    ADD [ReportingMode] NVARCHAR(50) NOT NULL DEFAULT 'Structured';
    
    PRINT 'SUCCESS: ReportingMode added to DiagnosticReports';
END
GO

-- 2. Update Users table to track global paradigm preference
-- This enables a persistent clinical workflow choice across the entire platform
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'PreferredReportingMode')
BEGIN
    ALTER TABLE [dbo].[Users] 
    ADD [PreferredReportingMode] NVARCHAR(50) NOT NULL DEFAULT 'Structured';
    
    PRINT 'SUCCESS: PreferredReportingMode added to Users';
END
GO

-- 3. Initialization: Standardize existing clinical records
-- Ensure zero NULL values for high-fidelity state recovery
UPDATE [dbo].[DiagnosticReports] SET [ReportingMode] = 'Structured' WHERE [ReportingMode] IS NULL;
UPDATE [dbo].[Users] SET [PreferredReportingMode] = 'Structured' WHERE [PreferredReportingMode] IS NULL;
GO
