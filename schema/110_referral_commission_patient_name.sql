-- ============================================================
-- Migration 110 - ReferralCommissions.PatientName (referral review #16)
-- The entity carried PatientName but it was never stored, so manual commissions
-- and payout lines without a visit lost the patient ("Unknown Patient").
-- Visit-linked rows keep reading the name from the visit; this column is the
-- fallback. Existing rows get '' (the name cannot be recovered for them).
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF COL_LENGTH('dbo.ReferralCommissions', 'PatientName') IS NULL
BEGIN
    ALTER TABLE [dbo].[ReferralCommissions]
        ADD [PatientName] NVARCHAR(255) NOT NULL
            CONSTRAINT [DF_ReferralCommissions_PatientName] DEFAULT (N'');
END
GO
PRINT 'Migration 110 applied: ReferralCommissions.PatientName.';
GO
