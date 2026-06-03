-- Migration: 64_appointment_supported_doctor.sql
-- Description: Per-appointment supporting doctor.
--
--   When the referral is "another person" (an agent, Referrers.IsDoctor = 0),
--   the agent may bring patients on behalf of MANY doctors. Which doctor a
--   given visit is referred for therefore varies per appointment — it is not a
--   fixed property of the agent. We store the chosen supporting doctor on the
--   appointment itself so each visit keeps its own correct referring doctor
--   (used as "Referred By" on the report), and changing it for one visit never
--   rewrites another. Nullable: empty for doctor-referred or self-referred visits.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'SupportedByDoctor'
              AND object_id = OBJECT_ID(N'[dbo].[Appointments]'))
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [SupportedByDoctor] NVARCHAR(200) NULL;
    PRINT 'Column dbo.Appointments.SupportedByDoctor added.';
END
ELSE PRINT 'Column dbo.Appointments.SupportedByDoctor already exists - skipped.';
GO
