-- ============================================================
-- 118 MONEY, PHASE 3: WHEN A PARTNER'S SHARE CAN BE PAID
-- Mirrors HospitalBillingSettings.PartnerPayWhenBilled (ApplicationDbContext).
--
--  1 = the share can be paid out once the patient's bill is made, whether or not
--      the patient has paid yet (the owner's choice, Nov 2026). Shares on bills the
--      patient still owes are marked "patient owes" so they can be held back.
--  0 = only after the patient has paid the bill in full (the rule before this).
-- A cancelled bill, a credit note or a write-off still takes the share back.
-- Requires 109. Safe to run more than once.
-- Rollback: rollback/118_rollback_partner_pay_when_billed.sql
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
SET NOCOUNT ON;
IF OBJECT_ID('dbo.HospitalBillingSettings', 'U') IS NULL
    THROW 51180, 'Run 109_hospital_billing_settings.sql first.', 1;
IF COL_LENGTH('dbo.HospitalBillingSettings', 'PartnerPayWhenBilled') IS NULL
    ALTER TABLE dbo.HospitalBillingSettings ADD PartnerPayWhenBilled BIT NOT NULL
        CONSTRAINT DF_HospitalBillingSettings_PartnerPayWhenBilled DEFAULT 1;
PRINT 'Migration 118 applied: partner share payable once the bill is made (per centre).';
