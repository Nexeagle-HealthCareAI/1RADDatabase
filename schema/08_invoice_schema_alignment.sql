/* =========================================================
   1Rad / Finance Hub
   Patch: 08_invoice_schema_alignment.sql
   Description: Aligns Invoices table with Domain Entity
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;

-- 1. Add PatientName column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Invoices]') AND name = N'PatientName')
BEGIN
    ALTER TABLE [dbo].[Invoices] ADD [PatientName] NVARCHAR(255) NULL;
END
GO

-- 2. Add PaidAt column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Invoices]') AND name = N'PaidAt')
BEGIN
    ALTER TABLE [dbo].[Invoices] ADD [PaidAt] DATETIME NULL;
END
GO

-- 3. Backfill PatientName from Patients table for existing records
UPDATE i
SET i.PatientName = p.FullName
FROM [dbo].[Invoices] i
JOIN [dbo].[Patients] p ON i.PatientId = p.PatientId
WHERE i.PatientName IS NULL;

-- 4. Set PatientName as NOT NULL if desired (after backfill)
ALTER TABLE [dbo].[Invoices] ALTER COLUMN [PatientName] NVARCHAR(255) NOT NULL;
GO

COMMIT;
