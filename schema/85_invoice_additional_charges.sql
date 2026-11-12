-- Add AdditionalCharges and AdditionalChargesReason to Invoices table
-- Guarded (Oct 2026): originally a bare ALTER, which failed on any re-apply.
-- Behaviour on a fresh database is unchanged.
IF COL_LENGTH('dbo.Invoices', 'AdditionalCharges') IS NULL
    ALTER TABLE [dbo].[Invoices]
    ADD [AdditionalCharges] decimal(18,2) NOT NULL DEFAULT 0;
GO
IF COL_LENGTH('dbo.Invoices', 'AdditionalChargesReason') IS NULL
    ALTER TABLE [dbo].[Invoices]
    ADD [AdditionalChargesReason] nvarchar(max) NULL;
GO
