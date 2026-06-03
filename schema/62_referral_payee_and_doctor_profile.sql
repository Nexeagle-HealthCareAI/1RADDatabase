-- Migration: 62_referral_payee_and_doctor_profile.sql
-- Description: Referral "pay-to" person + referring-doctor profile.
--
--   1) A referral cut isn't always paid to the doctor who sent the patient —
--      sometimes it's owed to an associated person (the doctor's agent). Each
--      ReferralCommission now remembers WHO to pay: PayeeName + PayeeContact.
--      NULL means "pay the referring doctor" (the common case); a value means
--      pay that named person instead. The payout screen pays whoever is named.
--
--   2) The referring doctor (Referrer) gets optional profile fields — Email,
--      Specialty, Degree — captured on the referrer form and shown at booking.
--
--   All columns are nullable; no backfill needed. Existing commissions keep
--   PayeeName/PayeeContact NULL and continue to pay the referrer as before.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- 1) ReferralCommissions: who actually gets paid -----------------------------
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'PayeeName'
              AND object_id = OBJECT_ID(N'[dbo].[ReferralCommissions]'))
BEGIN
    ALTER TABLE [dbo].[ReferralCommissions] ADD [PayeeName] NVARCHAR(200) NULL;
    PRINT 'Column dbo.ReferralCommissions.PayeeName added.';
END
ELSE PRINT 'Column dbo.ReferralCommissions.PayeeName already exists - skipped.';
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'PayeeContact'
              AND object_id = OBJECT_ID(N'[dbo].[ReferralCommissions]'))
BEGIN
    ALTER TABLE [dbo].[ReferralCommissions] ADD [PayeeContact] NVARCHAR(40) NULL;
    PRINT 'Column dbo.ReferralCommissions.PayeeContact added.';
END
ELSE PRINT 'Column dbo.ReferralCommissions.PayeeContact already exists - skipped.';
GO

-- 2) Referrers: optional referring-doctor profile ----------------------------
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'Email'
              AND object_id = OBJECT_ID(N'[dbo].[Referrers]'))
BEGIN
    ALTER TABLE [dbo].[Referrers] ADD [Email] NVARCHAR(200) NULL;
    PRINT 'Column dbo.Referrers.Email added.';
END
ELSE PRINT 'Column dbo.Referrers.Email already exists - skipped.';
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'Specialty'
              AND object_id = OBJECT_ID(N'[dbo].[Referrers]'))
BEGIN
    ALTER TABLE [dbo].[Referrers] ADD [Specialty] NVARCHAR(120) NULL;
    PRINT 'Column dbo.Referrers.Specialty added.';
END
ELSE PRINT 'Column dbo.Referrers.Specialty already exists - skipped.';
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'Degree'
              AND object_id = OBJECT_ID(N'[dbo].[Referrers]'))
BEGIN
    ALTER TABLE [dbo].[Referrers] ADD [Degree] NVARCHAR(120) NULL;
    PRINT 'Column dbo.Referrers.Degree added.';
END
ELSE PRINT 'Column dbo.Referrers.Degree already exists - skipped.';
GO
