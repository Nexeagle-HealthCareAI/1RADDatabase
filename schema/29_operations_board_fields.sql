/* =========================================================
   1Rad / Clinical Operations Hub
   DDL Script: Delay Reason & Report Delivery Pipeline Columns
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Add DelayReason column to Appointments (idempotent)
IF COL_LENGTH('dbo.Appointments', 'DelayReason') IS NULL
BEGIN
    ALTER TABLE [dbo].[Appointments]
    ADD [DelayReason] NVARCHAR(MAX) NULL;

    PRINT 'Column DelayReason added successfully.';
END
ELSE
BEGIN
    PRINT 'Column DelayReason already exists. Skipping ALTER.';
END
GO

-- 2. Add ReportProgressStatus column to Appointments (idempotent)
IF COL_LENGTH('dbo.Appointments', 'ReportProgressStatus') IS NULL
BEGIN
    ALTER TABLE [dbo].[Appointments]
    ADD [ReportProgressStatus] NVARCHAR(50) NOT NULL CONSTRAINT [DF_Appointments_ReportProgressStatus] DEFAULT 'NOT_STARTED';

    PRINT 'Column ReportProgressStatus added successfully.';
END
ELSE
BEGIN
    PRINT 'Column ReportProgressStatus already exists. Skipping ALTER.';
END
GO
