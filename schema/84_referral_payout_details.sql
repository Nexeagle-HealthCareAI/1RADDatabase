-- ============================================================
-- Migration 84 — Referral Commission Payout Detail Fields
-- Adds who paid and full recipient details for audit + export.
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('ReferralCommissions') AND name = 'PaidBy')
    ALTER TABLE ReferralCommissions ADD PaidBy NVARCHAR(200) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('ReferralCommissions') AND name = 'PayeeEmail')
    ALTER TABLE ReferralCommissions ADD PayeeEmail NVARCHAR(200) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('ReferralCommissions') AND name = 'PayeeAddress')
    ALTER TABLE ReferralCommissions ADD PayeeAddress NVARCHAR(500) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('ReferralCommissions') AND name = 'CreatedBy')
    ALTER TABLE ReferralCommissions ADD CreatedBy NVARCHAR(200) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('ReferralCommissions') AND name = 'UpdatedBy')
    ALTER TABLE ReferralCommissions ADD UpdatedBy NVARCHAR(200) NULL;

PRINT 'Migration 84 applied: ReferralCommissions payout detail columns added.';
