-- ============================================================
-- Migration 103 - Hospitals.PublicContact / PublicEmail
-- (appointments/billing/referral review, Oct 2026: R9)
--
-- The referral portal used to show doctors and agents a centre admin's personal
-- mobile and email (the first admin user found). These columns hold the centre's
-- own front-desk number and email; the portal shows only these. Set them in
-- Admin → Centre details.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF COL_LENGTH('dbo.Hospitals', 'PublicContact') IS NULL
    ALTER TABLE [dbo].[Hospitals] ADD [PublicContact] NVARCHAR(20) NULL;
GO
IF COL_LENGTH('dbo.Hospitals', 'PublicEmail') IS NULL
    ALTER TABLE [dbo].[Hospitals] ADD [PublicEmail] NVARCHAR(255) NULL;
GO
PRINT 'Migration 103 applied: Hospitals.PublicContact / PublicEmail.';
GO
