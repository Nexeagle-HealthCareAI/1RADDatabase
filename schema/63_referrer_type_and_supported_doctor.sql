-- Migration: 63_referrer_type_and_supported_doctor.sql
-- Description: Payee-first referral model.
--
--   A referral record (Referrer) now represents the PAYEE — whoever collects
--   the referral cut. It is one of two kinds:
--     • a DOCTOR who refers and collects for themselves  (IsDoctor = 1)
--       → the Email / Specialty / Degree profile (added in script 62) applies.
--     • ANOTHER PERSON (an agent) who collects on a doctor's behalf
--       → SupportedByDoctor names the doctor they bring patients from.
--
--   Existing referrers are all doctors, so IsDoctor defaults to 1 — they become
--   self-paying doctors with no behaviour change. SupportedByDoctor is nullable.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'IsDoctor'
              AND object_id = OBJECT_ID(N'[dbo].[Referrers]'))
BEGIN
    ALTER TABLE [dbo].[Referrers]
        ADD [IsDoctor] BIT NOT NULL CONSTRAINT [DF_Referrers_IsDoctor] DEFAULT (1);
    PRINT 'Column dbo.Referrers.IsDoctor added (default 1).';
END
ELSE PRINT 'Column dbo.Referrers.IsDoctor already exists - skipped.';
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'SupportedByDoctor'
              AND object_id = OBJECT_ID(N'[dbo].[Referrers]'))
BEGIN
    ALTER TABLE [dbo].[Referrers] ADD [SupportedByDoctor] NVARCHAR(200) NULL;
    PRINT 'Column dbo.Referrers.SupportedByDoctor added.';
END
ELSE PRINT 'Column dbo.Referrers.SupportedByDoctor already exists - skipped.';
GO
