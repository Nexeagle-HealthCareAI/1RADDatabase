-- Rollback for migration 110 (ReferralCommissions.PatientName).
-- Deploy the previous API first: the current one maps this column.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF COL_LENGTH('dbo.ReferralCommissions', 'PatientName') IS NOT NULL
BEGIN
    IF OBJECT_ID('dbo.DF_ReferralCommissions_PatientName', 'D') IS NOT NULL
        ALTER TABLE [dbo].[ReferralCommissions] DROP CONSTRAINT [DF_ReferralCommissions_PatientName];
    ALTER TABLE [dbo].[ReferralCommissions] DROP COLUMN [PatientName];
END
GO
PRINT 'Rollback 110 applied.';
GO
