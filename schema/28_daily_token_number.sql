/* =========================================================
   1Rad / Clinical Core
   DDL Script: Daily Token Number — Persistent Appointment Sequencing
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Add DailyTokenNumber column to Appointments (idempotent)
IF COL_LENGTH('dbo.Appointments', 'DailyTokenNumber') IS NULL
BEGIN
    ALTER TABLE [dbo].[Appointments]
    ADD [DailyTokenNumber] INT NULL;

    PRINT 'Column DailyTokenNumber added successfully.';
END
ELSE
BEGIN
    PRINT 'Column DailyTokenNumber already exists. Skipping ALTER.';
END
GO

-- 2. Token assignment is now an APPLICATION concern (assigned on arrival),
--    not a deploy-time backfill.
--
--    The original backfill stamped a sequential token onto EVERY appointment
--    via ROW_NUMBER() PARTITION BY HospitalId, Date. That made sense under the
--    old "everyone gets a token at booking" model when it ran once over all-NULL
--    data. It is now BOTH obsolete and unsafe to re-run:
--
--      • Wrong: under the token-on-arrival model, DailyTokenNumber is meant to
--        stay NULL until the patient actually arrives. Backfilling would stamp
--        tokens onto un-arrived appointments.
--      • Broken: the deploy re-runs every script, so the partition now holds a
--        permanent MIX of assigned (non-NULL) and pending (NULL) tokens. The
--        ROW_NUMBER() is computed over ALL rows but only written to the NULL
--        ones, so a NULL row is handed a value an existing row already owns —
--        colliding with the filtered unique index
--        UX_Appointments_Hospital_Date_Token (script 61) and aborting the deploy.
--
--    Existing rows were filled by the original one-time run long ago; new rows
--    are assigned on arrival by UpdateAppointmentStatus. So this step is now a
--    deliberate no-op, kept for migration-history continuity.
PRINT 'Token backfill retired: DailyTokenNumber is assigned on arrival by the application.';
GO
