-- ============================================================
-- SUBSCRIPTION EDITIONS + METERED PACS STORAGE PRICING
-- Run this against your 1RadDb database. Idempotent / re-runnable.
--
-- 1. dbo.SubscriptionPlans gains Edition / Modules / IncludedStorageGb /
--    PerGbOveragePrice, and is reseeded to one plan per (edition × cycle).
-- 2. dbo.SubscriptionPaymentRequests records the purchased PlanId / Modules +
--    the storage overage that made up the amount.
--
-- ⚠ PRICES + storage allowances are PLACEHOLDERS — adjust to real values.
-- ============================================================

SET NOCOUNT ON;

-- ── 1. SubscriptionPlans columns ────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='SubscriptionPlans' AND COLUMN_NAME='Edition')
BEGIN
    ALTER TABLE dbo.SubscriptionPlans ADD Edition NVARCHAR(20) NOT NULL CONSTRAINT DF_SubscriptionPlans_Edition DEFAULT 'RIS+PACS';
    PRINT '  + SubscriptionPlans.Edition';
END
ELSE PRINT '  = SubscriptionPlans.Edition exists.';
GO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='SubscriptionPlans' AND COLUMN_NAME='Modules')
BEGIN
    ALTER TABLE dbo.SubscriptionPlans ADD Modules NVARCHAR(50) NOT NULL CONSTRAINT DF_SubscriptionPlans_Modules DEFAULT 'RIS,PACS';
    PRINT '  + SubscriptionPlans.Modules';
END
ELSE PRINT '  = SubscriptionPlans.Modules exists.';
GO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='SubscriptionPlans' AND COLUMN_NAME='IncludedStorageGb')
BEGIN
    ALTER TABLE dbo.SubscriptionPlans ADD IncludedStorageGb INT NULL;
    PRINT '  + SubscriptionPlans.IncludedStorageGb';
END
ELSE PRINT '  = SubscriptionPlans.IncludedStorageGb exists.';
GO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='SubscriptionPlans' AND COLUMN_NAME='PerGbOveragePrice')
BEGIN
    ALTER TABLE dbo.SubscriptionPlans ADD PerGbOveragePrice DECIMAL(18,2) NOT NULL CONSTRAINT DF_SubscriptionPlans_PerGbOverage DEFAULT 0;
    PRINT '  + SubscriptionPlans.PerGbOveragePrice';
END
ELSE PRINT '  = SubscriptionPlans.PerGbOveragePrice exists.';
GO

-- ── 2. SubscriptionPaymentRequests columns ──────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='SubscriptionPaymentRequests' AND COLUMN_NAME='PlanId')
    ALTER TABLE dbo.SubscriptionPaymentRequests ADD PlanId UNIQUEIDENTIFIER NULL;
GO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='SubscriptionPaymentRequests' AND COLUMN_NAME='Modules')
    ALTER TABLE dbo.SubscriptionPaymentRequests ADD Modules NVARCHAR(50) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='SubscriptionPaymentRequests' AND COLUMN_NAME='StorageOverageGb')
    ALTER TABLE dbo.SubscriptionPaymentRequests ADD StorageOverageGb INT NOT NULL CONSTRAINT DF_SPR_OverageGb DEFAULT 0;
GO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='SubscriptionPaymentRequests' AND COLUMN_NAME='StorageOverageAmount')
    ALTER TABLE dbo.SubscriptionPaymentRequests ADD StorageOverageAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_SPR_OverageAmt DEFAULT 0;
GO
PRINT '  = SubscriptionPaymentRequests edition/overage columns ensured.';
GO

-- ── 3. Reseed plans (edition × cycle). Existing 2 GUIDs become RIS+PACS. ─────
-- RIS+PACS (existing rows) — set the edition fields.
UPDATE dbo.SubscriptionPlans SET Edition='RIS+PACS', Modules='RIS,PACS', IncludedStorageGb=50, PerGbOveragePrice=50
    WHERE PlanId IN ('A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D','B2C3D4E5-F6A7-4B6C-9D0E-1F2A3B4C5D6E');

-- RIS only + Cloud PACS only — insert if missing (PLACEHOLDER prices).
MERGE dbo.SubscriptionPlans AS t
USING (VALUES
    ('C3D4E5F6-A7B8-4C7D-AE1F-2A3B4C5D6E7F','Monthly','RIS','RIS',        2999.00, 30,  0,  1000.00, NULL, 0.00),
    ('D4E5F6A7-B8C9-4D8E-BF2A-3B4C5D6E7F80','Yearly', 'RIS','RIS',       32388.00, 365, 10, 10800.00, NULL, 0.00),
    ('E5F6A7B8-C9D0-4E9F-C03B-4C5D6E7F8091','Monthly','PACS','PACS',      3499.00, 30,  0,  1000.00, 100,  50.00),
    ('F6A7B8C9-D0E1-4F90-D14C-5D6E7F8091A2','Yearly', 'PACS','PACS',     37788.00, 365, 10, 10800.00, 100,  50.00)
) AS s (PlanId, Name, Edition, Modules, Price, DurationInDays, DiscountPercentage, PerAdditionalDoctorPrice, IncludedStorageGb, PerGbOveragePrice)
ON t.PlanId = s.PlanId
WHEN NOT MATCHED THEN
    INSERT (PlanId, Name, Edition, Modules, Price, DurationInDays, DiscountPercentage, PerAdditionalDoctorPrice, IncludedStorageGb, PerGbOveragePrice, IsActive, CreatedAt)
    VALUES (s.PlanId, s.Name, s.Edition, s.Modules, s.Price, s.DurationInDays, s.DiscountPercentage, s.PerAdditionalDoctorPrice, s.IncludedStorageGb, s.PerGbOveragePrice, 1, SYSUTCDATETIME());
PRINT '  = SubscriptionPlans reseeded (6 editions × cycles).';
GO
