/* =========================================================
   1Rad / Finance Hub
   DDL Script: Referral Commission & Payout Infrastructure
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;

/* =========================================================
   1. ReferralCommissions Table
   ========================================================= */
IF OBJECT_ID('dbo.ReferralCommissions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReferralCommissions (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY CONSTRAINT [DF_ReferralCommissions_Id] DEFAULT NEWID(),
        [ReferrerId] UNIQUEIDENTIFIER NOT NULL,
        [ReferrerName] NVARCHAR(255) NOT NULL,
        [CommissionAmount] DECIMAL(18, 2) NOT NULL,
        [AccumulatedTotal] DECIMAL(18, 2) NOT NULL,
        [Status] NVARCHAR(50) DEFAULT 'Pending' NOT NULL, -- Pending, Paid, Cancelled
        [TransactionDate] DATETIME NOT NULL DEFAULT GETUTCDATE(),
        [PaymentDate] DATETIME NULL,
        [ReferenceNumber] NVARCHAR(100) NULL,
        [Remarks] NVARCHAR(MAX) NULL,
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT [FK_ReferralCommissions_Referrers] FOREIGN KEY ([ReferrerId]) REFERENCES [dbo].[Referrers] ([ReferrerId]) ON DELETE NO ACTION,
        CONSTRAINT [FK_ReferralCommissions_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );

    CREATE INDEX [IX_ReferralCommissions_ReferrerId] ON dbo.ReferralCommissions ([ReferrerId]);
    CREATE INDEX [IX_ReferralCommissions_HospitalId_Date] ON dbo.ReferralCommissions ([HospitalId], [TransactionDate]);
END

/* =========================================================
   2. Analytics Views for Referral Commissions
   ========================================================= */

-- 2.1 Referrer Payout Summary
GO
CREATE OR ALTER VIEW dbo.vw_ReferrerPayoutSummary
AS
SELECT 
    HospitalId,
    ReferrerId,
    ReferrerName,
    SUM(CASE WHEN [Status] = 'Paid' THEN CommissionAmount ELSE 0 END) AS TotalPaid,
    SUM(CASE WHEN [Status] = 'Pending' THEN CommissionAmount ELSE 0 END) AS TotalPending,
    SUM(CommissionAmount) AS LifetimeEarnings
FROM dbo.ReferralCommissions
GROUP BY HospitalId, ReferrerId, ReferrerName;
GO

COMMIT;
GO
