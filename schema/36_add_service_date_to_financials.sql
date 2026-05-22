-- Migration: 36_add_service_date_to_financials.sql
-- Description: Adds a ServiceDate column to Invoices and ReferralCommissions to decouple clinical service dates from transaction timestamps.

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[Invoices]') AND name = 'ServiceDate'
)
BEGIN
    ALTER TABLE [dbo].[Invoices] ADD [ServiceDate] DATETIME2 NULL;
    
    EXEC('UPDATE [dbo].[Invoices] SET [ServiceDate] = [CreatedAt] WHERE [ServiceDate] IS NULL;');
    
    ALTER TABLE [dbo].[Invoices] ALTER COLUMN [ServiceDate] DATETIME2 NOT NULL;
    PRINT 'Column dbo.Invoices.ServiceDate added successfully.';
END
ELSE
BEGIN
    PRINT 'Column dbo.Invoices.ServiceDate already exists — skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[ReferralCommissions]') AND name = 'ServiceDate'
)
BEGIN
    ALTER TABLE [dbo].[ReferralCommissions] ADD [ServiceDate] DATETIME2 NULL;
    
    EXEC('UPDATE [dbo].[ReferralCommissions] SET [ServiceDate] = [TransactionDate] WHERE [ServiceDate] IS NULL;');
    
    ALTER TABLE [dbo].[ReferralCommissions] ALTER COLUMN [ServiceDate] DATETIME2 NOT NULL;
    PRINT 'Column dbo.ReferralCommissions.ServiceDate added successfully.';
END
ELSE
BEGIN
    PRINT 'Column dbo.ReferralCommissions.ServiceDate already exists — skipped.';
END
GO
