-- ============================================================
-- Migration 106 - Referral payouts with TDS (review R10, R12)
-- A payout header records what actually changed hands: gross, deficit recovered,
-- TDS (category, rate, amount), net, mode, reference and payee PAN. Each commission
-- row paid in it points to it. Referrers get a PAN.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF COL_LENGTH('dbo.Referrers', 'Pan') IS NULL
    ALTER TABLE [dbo].[Referrers] ADD [Pan] NVARCHAR(10) NULL;
GO
IF OBJECT_ID('dbo.ReferralPayouts', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[ReferralPayouts] (
        [Id]               UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ReferralPayouts_Id] DEFAULT (NEWID()),
        [HospitalId]       UNIQUEIDENTIFIER NOT NULL,
        [PayoutNumber]     NVARCHAR(20)     NOT NULL,
        [ReferrerId]       UNIQUEIDENTIFIER NOT NULL,
        [PayeeName]        NVARCHAR(200)    NOT NULL,
        [PayeePan]         NVARCHAR(10)     NULL,
        [FinancialYear]    NVARCHAR(7)      NOT NULL,
        [PaidAt]           DATETIME2        NOT NULL,
        [PaidBy]           NVARCHAR(200)    NOT NULL,
        [CreatedByUserId]  UNIQUEIDENTIFIER NULL,
        [Mode]             NVARCHAR(20)     NOT NULL,
        [Reference]        NVARCHAR(100)    NULL,
        [Gross]            DECIMAL(18,2)    NOT NULL,
        [DeficitRecovered] DECIMAL(18,2)    NOT NULL,
        [TdsCategory]      NVARCHAR(20)     NOT NULL,
        [TdsRate]          DECIMAL(18,2)    NOT NULL,
        [TdsAmount]        DECIMAL(18,2)    NOT NULL,
        [Net]              DECIMAL(18,2)    NOT NULL,
        [TdsNote]          NVARCHAR(500)    NULL,
        CONSTRAINT [PK_ReferralPayouts] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_ReferralPayouts_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );
    CREATE INDEX [IX_ReferralPayouts_Hospital_Referrer_FY] ON [dbo].[ReferralPayouts] ([HospitalId], [ReferrerId], [FinancialYear]);
    CREATE INDEX [IX_ReferralPayouts_Hospital_PaidAt] ON [dbo].[ReferralPayouts] ([HospitalId], [PaidAt]);
    CREATE UNIQUE INDEX [IX_ReferralPayouts_Hospital_Number] ON [dbo].[ReferralPayouts] ([HospitalId], [PayoutNumber]);
END
GO
IF COL_LENGTH('dbo.ReferralCommissions', 'PayoutId') IS NULL
    ALTER TABLE [dbo].[ReferralCommissions] ADD [PayoutId] UNIQUEIDENTIFIER NULL;
GO
PRINT 'Migration 106 applied: ReferralPayouts, Referrers.Pan, ReferralCommissions.PayoutId.';
GO
