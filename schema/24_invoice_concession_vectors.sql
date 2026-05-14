-- Add Triple-Vector Deduction Tracking to Invoices
IF COL_LENGTH('dbo.Invoices', 'CentreDiscount') IS NULL
BEGIN
    ALTER TABLE [dbo].[Invoices] ADD [CentreDiscount] DECIMAL(18, 2) NOT NULL DEFAULT 0;
END

IF COL_LENGTH('dbo.Invoices', 'ReferrerDiscount') IS NULL
BEGIN
    ALTER TABLE [dbo].[Invoices] ADD [ReferrerDiscount] DECIMAL(18, 2) NOT NULL DEFAULT 0;
END

IF COL_LENGTH('dbo.Invoices', 'InstitutionalDeduction') IS NULL
BEGIN
    ALTER TABLE [dbo].[Invoices] ADD [InstitutionalDeduction] DECIMAL(18, 2) NOT NULL DEFAULT 0;
END
GO
