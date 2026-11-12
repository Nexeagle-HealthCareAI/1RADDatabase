-- Rollback for 118_partner_pay_when_billed.sql. Roll the API back FIRST.
SET NOCOUNT ON;
IF COL_LENGTH('dbo.HospitalBillingSettings', 'PartnerPayWhenBilled') IS NOT NULL
BEGIN
    ALTER TABLE dbo.HospitalBillingSettings DROP CONSTRAINT DF_HospitalBillingSettings_PartnerPayWhenBilled;
    ALTER TABLE dbo.HospitalBillingSettings DROP COLUMN PartnerPayWhenBilled;
END
PRINT 'Rolled back 118';
