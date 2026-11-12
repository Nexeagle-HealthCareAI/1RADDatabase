-- Rollback for 116_money_receipts_discount_reasons.sql. Roll the API back FIRST.
-- Drops receipt numbers, payment references and discount reasons already recorded.
SET NOCOUNT ON;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Payments_Hospital_Receipt' AND object_id = OBJECT_ID('dbo.Payments'))
    DROP INDEX IX_Payments_Hospital_Receipt ON dbo.Payments;
IF COL_LENGTH('dbo.Payments', 'ReceiptNumber') IS NOT NULL ALTER TABLE dbo.Payments DROP COLUMN ReceiptNumber;
IF COL_LENGTH('dbo.Payments', 'Reference') IS NOT NULL ALTER TABLE dbo.Payments DROP COLUMN Reference;
IF COL_LENGTH('dbo.Invoices', 'DiscountByUserId') IS NOT NULL ALTER TABLE dbo.Invoices DROP COLUMN DiscountByUserId;
IF COL_LENGTH('dbo.Invoices', 'DiscountReason') IS NOT NULL ALTER TABLE dbo.Invoices DROP COLUMN DiscountReason;
IF COL_LENGTH('dbo.HospitalBillingSettings', 'DiscountReasonRequired') IS NOT NULL
BEGIN
    ALTER TABLE dbo.HospitalBillingSettings DROP CONSTRAINT DF_HospitalBillingSettings_DiscReason;
    ALTER TABLE dbo.HospitalBillingSettings DROP COLUMN DiscountReasonRequired;
END
IF COL_LENGTH('dbo.HospitalBillingSettings', 'AccountantDiscountLimitPercent') IS NOT NULL
BEGIN
    ALTER TABLE dbo.HospitalBillingSettings DROP CONSTRAINT CK_HospitalBillingSettings_AccLimit;
    ALTER TABLE dbo.HospitalBillingSettings DROP COLUMN AccountantDiscountLimitPercent;
END
PRINT 'Rolled back 116';
