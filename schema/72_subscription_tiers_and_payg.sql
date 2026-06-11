-- ============================================================
-- SUBSCRIPTION TIERS + USER/SITE CAPS + PER-STUDY PAYG
-- Run against 1RadDb. Idempotent / re-runnable.
--
-- Adds the tier/limit/PAYG columns, retires the two legacy single-price plans
-- from the catalog (kept for FK integrity on existing subscriptions), and
-- merges in the full edition × tier catalog (+ PAYG + Chain per edition).
-- ⚠ PRICES / allowances / caps are PLACEHOLDERS — adjust to real values.
-- ============================================================

SET NOCOUNT ON;

-- ── SubscriptionPlans columns ───────────────────────────────────────────────
IF COL_LENGTH('dbo.SubscriptionPlans','Tier') IS NULL
    ALTER TABLE dbo.SubscriptionPlans ADD Tier NVARCHAR(20) NOT NULL CONSTRAINT DF_Plans_Tier DEFAULT 'Starter';
GO
IF COL_LENGTH('dbo.SubscriptionPlans','BillingMode') IS NULL
    ALTER TABLE dbo.SubscriptionPlans ADD BillingMode NVARCHAR(20) NOT NULL CONSTRAINT DF_Plans_BillingMode DEFAULT 'Subscription';
GO
IF COL_LENGTH('dbo.SubscriptionPlans','PerStudyPrice') IS NULL
    ALTER TABLE dbo.SubscriptionPlans ADD PerStudyPrice DECIMAL(18,2) NOT NULL CONSTRAINT DF_Plans_PerStudy DEFAULT 0;
GO
IF COL_LENGTH('dbo.SubscriptionPlans','MaxUsers') IS NULL ALTER TABLE dbo.SubscriptionPlans ADD MaxUsers INT NULL;
GO
IF COL_LENGTH('dbo.SubscriptionPlans','MaxSites') IS NULL ALTER TABLE dbo.SubscriptionPlans ADD MaxSites INT NULL;
GO
IF COL_LENGTH('dbo.SubscriptionPlans','IsCustom') IS NULL
    ALTER TABLE dbo.SubscriptionPlans ADD IsCustom BIT NOT NULL CONSTRAINT DF_Plans_IsCustom DEFAULT 0;
GO

-- ── HospitalSubscriptions columns (copied from plan at activation) ──────────
IF COL_LENGTH('dbo.HospitalSubscriptions','BillingMode') IS NULL
    ALTER TABLE dbo.HospitalSubscriptions ADD BillingMode NVARCHAR(20) NOT NULL CONSTRAINT DF_Subs_BillingMode DEFAULT 'Subscription';
GO
IF COL_LENGTH('dbo.HospitalSubscriptions','PerStudyPrice') IS NULL
    ALTER TABLE dbo.HospitalSubscriptions ADD PerStudyPrice DECIMAL(18,2) NOT NULL CONSTRAINT DF_Subs_PerStudy DEFAULT 0;
GO
IF COL_LENGTH('dbo.HospitalSubscriptions','MaxUsers') IS NULL ALTER TABLE dbo.HospitalSubscriptions ADD MaxUsers INT NULL;
GO
IF COL_LENGTH('dbo.HospitalSubscriptions','MaxSites') IS NULL ALTER TABLE dbo.HospitalSubscriptions ADD MaxSites INT NULL;
GO

-- ── Retire the two legacy single-price plans from the catalog (keep rows so
--    existing subscriptions' PlanId FK stays valid). ─────────────────────────
UPDATE dbo.SubscriptionPlans SET IsActive = 0
    WHERE PlanId IN ('A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D','B2C3D4E5-F6A7-4B6C-9D0E-1F2A3B4C5D6E')
      AND Tier = 'Starter';   -- only if not already migrated
GO

-- ── Merge the full catalog (natural key = Edition+Tier+Name+BillingMode). ───
MERGE dbo.SubscriptionPlans AS t
USING (VALUES
  -- Edition, Tier, Name, Modules, Price, Days, Disc, PerDoc, Gb, PerGb, BillingMode, PerStudy, MaxUsers, MaxSites, IsCustom
  ('RIS','Starter','Monthly','RIS',          1999,  30,  0, 1000, NULL,  0, 'Subscription', 0, 2,    1,    0),
  ('RIS','Starter','Yearly', 'RIS',         21589, 365, 10,10800, NULL,  0, 'Subscription', 0, 2,    1,    0),
  ('RIS','Growth', 'Monthly','RIS',          4999,  30,  0, 1000, NULL,  0, 'Subscription', 0, 5,    1,    0),
  ('RIS','Growth', 'Yearly', 'RIS',         53989, 365, 10,10800, NULL,  0, 'Subscription', 0, 5,    1,    0),
  ('RIS','Clinic', 'Monthly','RIS',          9999,  30,  0, 1000, NULL,  0, 'Subscription', 0, 10,   3,    0),
  ('RIS','Clinic', 'Yearly', 'RIS',        107989, 365, 10,10800, NULL,  0, 'Subscription', 0, 10,   3,    0),
  ('PACS','Starter','Monthly','PACS',        2999,  30,  0, 1000, 100,  50, 'Subscription', 0, 5,    1,    0),
  ('PACS','Starter','Yearly', 'PACS',       32389, 365, 10,10800, 100,  50, 'Subscription', 0, 5,    1,    0),
  ('PACS','Growth', 'Monthly','PACS',        6999,  30,  0, 1000, 500,  50, 'Subscription', 0, 10,   1,    0),
  ('PACS','Growth', 'Yearly', 'PACS',       75589, 365, 10,10800, 500,  50, 'Subscription', 0, 10,   1,    0),
  ('PACS','Clinic', 'Monthly','PACS',       14999,  30,  0, 1000, 1024, 50, 'Subscription', 0, 20,   3,    0),
  ('PACS','Clinic', 'Yearly', 'PACS',      161989, 365, 10,10800, 1024, 50, 'Subscription', 0, 20,   3,    0),
  ('RIS+PACS','Starter','Monthly','RIS,PACS', 3999,  30,  0, 1000, 100, 50, 'Subscription', 0, 2,    1,    0),
  ('RIS+PACS','Starter','Yearly', 'RIS,PACS',43189, 365, 10,10800, 100, 50, 'Subscription', 0, 2,    1,    0),
  ('RIS+PACS','Growth', 'Monthly','RIS,PACS', 9999,  30,  0, 1000, 500, 50, 'Subscription', 0, 5,    1,    0),
  ('RIS+PACS','Growth', 'Yearly', 'RIS,PACS',107989,365, 10,10800, 500, 50, 'Subscription', 0, 5,    1,    0),
  ('RIS+PACS','Clinic', 'Monthly','RIS,PACS',19999,  30,  0, 1000, 1024,50, 'Subscription', 0, 10,   3,    0),
  ('RIS+PACS','Clinic', 'Yearly', 'RIS,PACS',215989,365, 10,10800, 1024,50, 'Subscription', 0, 10,   3,    0),
  ('RIS','PAYG','PAYG','RIS',                   0,  30,  0,    0, NULL,  0, 'PerStudy',  8, NULL, NULL, 0),
  ('PACS','PAYG','PAYG','PACS',                 0,  30,  0,    0, NULL,  0, 'PerStudy', 15, NULL, NULL, 0),
  ('RIS+PACS','PAYG','PAYG','RIS,PACS',         0,  30,  0,    0, NULL,  0, 'PerStudy', 25, NULL, NULL, 0),
  ('RIS','Chain','Custom','RIS',                0,  30,  0,    0, NULL,  0, 'Subscription', 0, NULL, NULL, 1),
  ('PACS','Chain','Custom','PACS',              0,  30,  0,    0, NULL, 50, 'Subscription', 0, NULL, NULL, 1),
  ('RIS+PACS','Chain','Custom','RIS,PACS',      0,  30,  0,    0, NULL, 50, 'Subscription', 0, NULL, NULL, 1)
) AS s (Edition, Tier, Name, Modules, Price, DurationInDays, DiscountPercentage, PerAdditionalDoctorPrice, IncludedStorageGb, PerGbOveragePrice, BillingMode, PerStudyPrice, MaxUsers, MaxSites, IsCustom)
ON  t.Edition = s.Edition AND t.Tier = s.Tier AND t.Name = s.Name AND t.BillingMode = s.BillingMode AND t.IsActive = 1
WHEN MATCHED THEN UPDATE SET
    t.Modules = s.Modules, t.Price = s.Price, t.DurationInDays = s.DurationInDays, t.DiscountPercentage = s.DiscountPercentage,
    t.PerAdditionalDoctorPrice = s.PerAdditionalDoctorPrice, t.IncludedStorageGb = s.IncludedStorageGb, t.PerGbOveragePrice = s.PerGbOveragePrice,
    t.PerStudyPrice = s.PerStudyPrice, t.MaxUsers = s.MaxUsers, t.MaxSites = s.MaxSites, t.IsCustom = s.IsCustom
WHEN NOT MATCHED THEN
    INSERT (PlanId, Edition, Tier, Name, Modules, Price, DurationInDays, DiscountPercentage, PerAdditionalDoctorPrice, IncludedStorageGb, PerGbOveragePrice, BillingMode, PerStudyPrice, MaxUsers, MaxSites, IsCustom, IsActive, CreatedAt)
    VALUES (NEWID(), s.Edition, s.Tier, s.Name, s.Modules, s.Price, s.DurationInDays, s.DiscountPercentage, s.PerAdditionalDoctorPrice, s.IncludedStorageGb, s.PerGbOveragePrice, s.BillingMode, s.PerStudyPrice, s.MaxUsers, s.MaxSites, s.IsCustom, 1, SYSUTCDATETIME());
PRINT '  = Subscription catalog merged (tiers + PAYG + Chain).';
GO
