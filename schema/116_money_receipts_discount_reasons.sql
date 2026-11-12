-- ============================================================
-- 116 MONEY, PHASE 1: RECEIPTS, PAYMENT REFERENCES, DISCOUNT REASONS
-- Mirrors Payment.Reference / Payment.ReceiptNumber, Invoice.DiscountReason /
-- Invoice.DiscountByUserId and two HospitalBillingSettings columns
-- (ApplicationDbContext).
--
--  Payments.Reference        UPI / card / bank reference typed at the counter
--  Payments.ReceiptNumber    "RCP-2627-00001": one number per collection, shared
--                            by the rows of a split cash + UPI payment. Running
--                            series per centre and financial year (SequenceCounters).
--  Invoices.DiscountReason   why the centre discount / deduction was given
--  Invoices.DiscountByUserId who gave it (or whose approval applied it)
--  HospitalBillingSettings.AccountantDiscountLimitPercent
--                            NULL = accountants may give any discount (as before)
--  HospitalBillingSettings.DiscountReasonRequired
--                            1 = a discount needs a reason. Default 0 so older
--                            screens keep working until the centre switches it on.
--
-- Requires 108 and 109. Safe to run more than once.
-- Rollback: rollback/116_rollback_money_receipts_discount_reasons.sql
-- ============================================================
SET NOCOUNT ON;

IF OBJECT_ID('dbo.HospitalBillingSettings', 'U') IS NULL
    THROW 51160, 'Run 109_hospital_billing_settings.sql first.', 1;

IF COL_LENGTH('dbo.Payments', 'Reference') IS NULL
    ALTER TABLE dbo.Payments ADD Reference NVARCHAR(60) NULL;
IF COL_LENGTH('dbo.Payments', 'ReceiptNumber') IS NULL
    ALTER TABLE dbo.Payments ADD ReceiptNumber NVARCHAR(20) NULL;

IF COL_LENGTH('dbo.Invoices', 'DiscountReason') IS NULL
    ALTER TABLE dbo.Invoices ADD DiscountReason NVARCHAR(200) NULL;
IF COL_LENGTH('dbo.Invoices', 'DiscountByUserId') IS NULL
    ALTER TABLE dbo.Invoices ADD DiscountByUserId UNIQUEIDENTIFIER NULL;

IF COL_LENGTH('dbo.HospitalBillingSettings', 'AccountantDiscountLimitPercent') IS NULL
    ALTER TABLE dbo.HospitalBillingSettings ADD AccountantDiscountLimitPercent DECIMAL(5,2) NULL
        CONSTRAINT CK_HospitalBillingSettings_AccLimit CHECK (AccountantDiscountLimitPercent IS NULL OR AccountantDiscountLimitPercent BETWEEN 0 AND 100);
IF COL_LENGTH('dbo.HospitalBillingSettings', 'DiscountReasonRequired') IS NULL
    ALTER TABLE dbo.HospitalBillingSettings ADD DiscountReasonRequired BIT NOT NULL
        CONSTRAINT DF_HospitalBillingSettings_DiscReason DEFAULT 0;

-- Rows of one collection share a receipt number, so this is not unique per row;
-- it is the lookup for "show me receipt RCP-2627-00042".
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Payments_Hospital_Receipt' AND object_id = OBJECT_ID('dbo.Payments'))
    EXEC('CREATE INDEX IX_Payments_Hospital_Receipt ON dbo.Payments (HospitalId, ReceiptNumber) WHERE ReceiptNumber IS NOT NULL');

PRINT 'Migration 116 applied: receipts, payment references, discount reasons.';
