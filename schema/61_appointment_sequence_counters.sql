-- Migration: 61_appointment_sequence_counters.sql
-- Description: Fix concurrent-booking races on the Appointment page.
--
--   Symptom: when 3-4 front-desk terminals book at the same instant, they
--   all read the same "count of appointments" BEFORE any of them commits,
--   so they all compute the SAME daily token number and the SAME APP-###
--   display id. Nothing in the DB stopped the duplicates.
--
--   Fix: a tiny counter table whose values are handed out with an atomic
--   "increment-and-return" inside a single locked statement (see
--   ApplicationDbContext.NextSequenceValueAsync). Two concurrent bookings
--   block on the same key range and come out with DISTINCT numbers.
--
--   This table is the source of truth for:
--     • the per-hospital, per-day token number  (key 'APPOINTMENT_TOKEN_<yyyy-MM-dd>')
--     • the global APP-### display id            (key 'APPOINTMENT_DISPLAY_ID',
--                                                  HospitalId = empty GUID sentinel)
--
--   No data backfill is needed: the handler seeds a brand-new counter row
--   from the current max/count, so existing appointments keep their numbers
--   and the next one continues the sequence.
--
--   The two UNIQUE indexes below are defense-in-depth — if the counter logic
--   ever regressed, the database itself would reject a duplicate. They are
--   created ONLY when the existing data is already clean, so this script is
--   safe to run on a live database that may carry a historical duplicate.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- 1) The counter table -------------------------------------------------------
IF NOT EXISTS (
    SELECT * FROM sys.tables
    WHERE name = 'SequenceCounters' AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    CREATE TABLE [dbo].[SequenceCounters] (
        -- Scope of the counter. The global display-id counter uses the empty
        -- GUID '00000000-...'; per-hospital counters use the real HospitalId.
        [HospitalId]   UNIQUEIDENTIFIER NOT NULL,
        -- Logical counter name, e.g. 'APPOINTMENT_DISPLAY_ID' or
        -- 'APPOINTMENT_TOKEN_2026-06-02'. Date is baked into the key so each
        -- hospital-day is its own independent sequence.
        [CounterKey]   NVARCHAR(80)     NOT NULL,
        [CounterValue] INT              NOT NULL,
        CONSTRAINT [PK_SequenceCounters] PRIMARY KEY CLUSTERED ([HospitalId], [CounterKey])
    );
    PRINT 'Table dbo.SequenceCounters created.';
END
ELSE PRINT 'Table dbo.SequenceCounters already exists - skipped.';
GO

-- 2) Safety-net UNIQUE index on Appointments.DisplayId -----------------------
-- Created only if no duplicate DisplayId currently exists, so a live DB that
-- already carries a historical collision isn't blocked from upgrading. If it
-- is skipped, clean up the duplicates and re-run this script to add it.
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'UX_Appointments_DisplayId'
      AND object_id = OBJECT_ID(N'[dbo].[Appointments]')
)
BEGIN
    IF EXISTS (
        SELECT [DisplayId]
        FROM [dbo].[Appointments]
        WHERE [DisplayId] IS NOT NULL
        GROUP BY [DisplayId]
        HAVING COUNT(*) > 1
    )
        PRINT 'SKIPPED UX_Appointments_DisplayId: duplicate DisplayId values exist. De-duplicate, then re-run.';
    ELSE
    BEGIN
        CREATE UNIQUE INDEX [UX_Appointments_DisplayId]
            ON [dbo].[Appointments] ([DisplayId])
            WHERE [DisplayId] IS NOT NULL;
        PRINT 'Unique index UX_Appointments_DisplayId created.';
    END
END
ELSE PRINT 'Index UX_Appointments_DisplayId already exists - skipped.';
GO

-- 3) Safety-net UNIQUE index on Appointments token per hospital+day ----------
-- DateTime is a full timestamp, so we need a persisted computed DATE column to
-- index "one token number per hospital per calendar day". Added only when the
-- existing data has no duplicate (HospitalId, day, token) triples.
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE name = 'AppointmentDate'
      AND object_id = OBJECT_ID(N'[dbo].[Appointments]')
)
BEGIN
    ALTER TABLE [dbo].[Appointments]
        ADD [AppointmentDate] AS (CONVERT(date, [DateTime])) PERSISTED;
    PRINT 'Computed column dbo.Appointments.AppointmentDate added.';
END
ELSE PRINT 'Column dbo.Appointments.AppointmentDate already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'UX_Appointments_Hospital_Date_Token'
      AND object_id = OBJECT_ID(N'[dbo].[Appointments]')
)
BEGIN
    IF EXISTS (
        SELECT [HospitalId], [AppointmentDate], [DailyTokenNumber]
        FROM [dbo].[Appointments]
        WHERE [DailyTokenNumber] IS NOT NULL
        GROUP BY [HospitalId], [AppointmentDate], [DailyTokenNumber]
        HAVING COUNT(*) > 1
    )
        PRINT 'SKIPPED UX_Appointments_Hospital_Date_Token: duplicate token values exist. De-duplicate, then re-run.';
    ELSE
    BEGIN
        CREATE UNIQUE INDEX [UX_Appointments_Hospital_Date_Token]
            ON [dbo].[Appointments] ([HospitalId], [AppointmentDate], [DailyTokenNumber])
            WHERE [DailyTokenNumber] IS NOT NULL;
        PRINT 'Unique index UX_Appointments_Hospital_Date_Token created.';
    END
END
ELSE PRINT 'Index UX_Appointments_Hospital_Date_Token already exists - skipped.';
GO

-- 4) Safety-net UNIQUE index on Referrers (HospitalId, Name) -----------------
-- Stops two simultaneous bookings naming the same NEW referrer from creating
-- two referrer rows (which would split that doctor's commissions). Created
-- only when no duplicate name-per-hospital already exists.
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'UX_Referrers_Hospital_Name'
      AND object_id = OBJECT_ID(N'[dbo].[Referrers]')
)
BEGIN
    IF EXISTS (
        SELECT [HospitalId], LOWER([Name])
        FROM [dbo].[Referrers]
        WHERE [Name] IS NOT NULL AND [DeletedAt] IS NULL
        GROUP BY [HospitalId], LOWER([Name])
        HAVING COUNT(*) > 1
    )
        PRINT 'SKIPPED UX_Referrers_Hospital_Name: duplicate referrer names exist. De-duplicate, then re-run.';
    ELSE
    BEGIN
        CREATE UNIQUE INDEX [UX_Referrers_Hospital_Name]
            ON [dbo].[Referrers] ([HospitalId], [Name])
            WHERE [Name] IS NOT NULL AND [DeletedAt] IS NULL;
        PRINT 'Unique index UX_Referrers_Hospital_Name created.';
    END
END
ELSE PRINT 'Index UX_Referrers_Hospital_Name already exists - skipped.';
GO
