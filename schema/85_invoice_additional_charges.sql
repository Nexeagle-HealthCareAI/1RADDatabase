-- Add AdditionalCharges and AdditionalChargesReason to Invoices table
ALTER TABLE [Invoices]
ADD [AdditionalCharges] decimal(18,2) NOT NULL DEFAULT 0,
    [AdditionalChargesReason] nvarchar(max) NULL;
GO
