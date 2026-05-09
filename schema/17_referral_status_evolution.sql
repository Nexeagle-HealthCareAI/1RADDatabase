/* =========================================================
   1Rad / Finance Hub
   Migration Script: Referral Status Evolution (UNPAID/PAID)
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;

-- 1. Ensure Status column exists and normalize existing data
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.ReferralCommissions') AND name = 'Status')
BEGIN
    PRINT 'PROTOCOL: Normalizing Referral Status metadata...';
    
    -- Update 'Pending' to 'UNPAID' for consistency with new UI
    UPDATE dbo.ReferralCommissions 
    SET [Status] = 'UNPAID' 
    WHERE [Status] = 'Pending' OR [Status] IS NULL;
    
    -- Ensure default is 'UNPAID'
    -- (We drop the old default if it exists and create a new one)
    DECLARE @DefaultConstraintName NVARCHAR(255);
    SELECT @DefaultConstraintName = name 
    FROM sys.default_constraints 
    WHERE parent_object_id = OBJECT_ID('dbo.ReferralCommissions') 
    AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.ReferralCommissions') AND name = 'Status');

    IF @DefaultConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE dbo.ReferralCommissions DROP CONSTRAINT ' + @DefaultConstraintName);
    END

    ALTER TABLE dbo.ReferralCommissions ADD CONSTRAINT [DF_ReferralCommissions_Status] DEFAULT 'UNPAID' FOR [Status];
END
ELSE
BEGIN
    PRINT 'PROTOCOL: Injecting missing Status column into ReferralCommissions...';
    ALTER TABLE dbo.ReferralCommissions ADD [Status] NVARCHAR(50) DEFAULT 'UNPAID' NOT NULL;
END

-- 2. Ensure PaymentDate column exists for settlement auditing
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.ReferralCommissions') AND name = 'PaymentDate')
BEGIN
    ALTER TABLE dbo.ReferralCommissions ADD [PaymentDate] DATETIME NULL;
END

-- 3. Update Analytics View to respect UNPAID status
GO
CREATE OR ALTER VIEW dbo.vw_ReferrerPayoutSummary
AS
SELECT 
    HospitalId,
    ReferrerId,
    ReferrerName,
    SUM(CASE WHEN [Status] = 'PAID' THEN CommissionAmount ELSE 0 END) AS TotalPaid,
    SUM(CASE WHEN [Status] = 'UNPAID' OR [Status] = 'Pending' THEN CommissionAmount ELSE 0 END) AS TotalPending,
    SUM(CommissionAmount) AS LifetimeEarnings
FROM dbo.ReferralCommissions
GROUP BY HospitalId, ReferrerId, ReferrerName;
GO

COMMIT;
PRINT 'FISCAL EVOLUTION COMPLETE: Referral status infrastructure stabilized.';
GO
