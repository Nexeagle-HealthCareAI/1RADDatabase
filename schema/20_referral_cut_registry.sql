/* =========================================================
   1Rad / Finance Hub Evolution
   DDL Script: Service Registry Referral Incentive Schema
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;

/* =========================================================
   1. Evolution of dbo.ServiceCharges
   Adding ReferralCutType and ReferralCutValue
   ========================================================= */

IF OBJECT_ID('dbo.ServiceCharges', 'U') IS NOT NULL
BEGIN
    -- Add ReferralCutValue if not exists
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.ServiceCharges') AND name = 'ReferralCutValue')
    BEGIN
        ALTER TABLE dbo.ServiceCharges
        ADD [ReferralCutValue] DECIMAL(18, 2) DEFAULT 0 NOT NULL;
    END
END

COMMIT;
GO
