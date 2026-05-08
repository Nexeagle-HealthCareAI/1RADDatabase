/* =========================================================
   1Rad / Finance Hub
   Patch: 16_invoice_discounting.sql
   Description: Introduces GrossAmount and DiscountAmount to Invoices
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;

-- 1. Add GrossAmount column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Invoices]') AND name = N'GrossAmount')
BEGIN
    ALTER TABLE [dbo].[Invoices] ADD [GrossAmount] DECIMAL(18, 2) NOT NULL DEFAULT 0;
END
GO

-- 2. Add DiscountAmount column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Invoices]') AND name = N'DiscountAmount')
BEGIN
    ALTER TABLE [dbo].[Invoices] ADD [DiscountAmount] DECIMAL(18, 2) NOT NULL DEFAULT 0;
END
GO

-- 3. Backfill GrossAmount for existing records (Initial Gross = TotalAmount)
-- This assumes existing records had no discounts recorded in the database.
UPDATE [dbo].[Invoices]
SET [GrossAmount] = [TotalAmount]
WHERE [GrossAmount] = 0 AND [TotalAmount] > 0;
GO

COMMIT;
