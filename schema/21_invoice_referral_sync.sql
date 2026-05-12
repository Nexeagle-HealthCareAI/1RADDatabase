/* =========================================================
   1Rad / Finance Hub Evolution
   DDL Script: Invoice Referral Synchronization
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;

/* =========================================================
   1. Evolution of dbo.Invoices
   Adding ReferralCutType and ReferralCutValue
   ========================================================= */

IF OBJECT_ID('dbo.Invoices', 'U') IS NOT NULL
BEGIN
    -- Add ReferralCutValue if not exists
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Invoices') AND name = 'ReferralCutValue')
    BEGIN
        ALTER TABLE dbo.Invoices
        ADD [ReferralCutValue] DECIMAL(18, 2) DEFAULT 0 NOT NULL;
    END
END


COMMIT;
GO
