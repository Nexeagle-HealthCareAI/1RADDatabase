-- Migration: 36_add_service_date_to_financials.sql
-- Description: Adds a ServiceDate column to Invoices and ReferralCommissions to decouple clinical service dates from transaction timestamps.

-- INVOICES TABLE
ALTER TABLE [Invoices]
ADD [ServiceDate] DATETIME2 NULL;
GO

-- Populate existing invoices to use their CreatedAt timestamp as the baseline ServiceDate
UPDATE [Invoices]
SET [ServiceDate] = [CreatedAt]
WHERE [ServiceDate] IS NULL;
GO

-- Make ServiceDate non-nullable now that existing data is populated
ALTER TABLE [Invoices]
ALTER COLUMN [ServiceDate] DATETIME2 NOT NULL;
GO

-- REFERRAL COMMISSIONS TABLE
ALTER TABLE [ReferralCommissions]
ADD [ServiceDate] DATETIME2 NULL;
GO

-- Populate existing commissions to use their TransactionDate as the baseline ServiceDate
UPDATE [ReferralCommissions]
SET [ServiceDate] = [TransactionDate]
WHERE [ServiceDate] IS NULL;
GO

-- Make ServiceDate non-nullable now that existing data is populated
ALTER TABLE [ReferralCommissions]
ALTER COLUMN [ServiceDate] DATETIME2 NOT NULL;
GO
