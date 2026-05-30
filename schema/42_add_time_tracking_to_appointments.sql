-- Migration: 42_add_time_tracking_to_appointments.sql
-- Description: Adds three turnaround-time milestone columns to Appointments.
--              ArrivedAt      → captured when Status → CONFIRMED (front desk
--                               marks the patient as physically arrived).
--              ScanStartedAt  → captured when Status → IN_PROGRESS (technician
--                               starts the scan).
--              DeliveredAt    → captured when ReportProgressStatus → DELIVERED
--                               (report handed to patient).
--              These three timestamps drive the on-premises clock and the
--              scan-to-delivery interval shown on every operations board, plus
--              the >3h overdue notification system. All three nullable; only
--              filled the FIRST time the relevant transition happens (the
--              command handlers enforce idempotency with a null-guard) so
--              double-clicks or status corrections can't reset the clock.
--              Historical rows stay NULL on purpose — no fake backfill.

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'ArrivedAt'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [ArrivedAt] DATETIME2 NULL;
    PRINT 'Column dbo.Appointments.ArrivedAt added.';
END
ELSE
BEGIN
    PRINT 'Column dbo.Appointments.ArrivedAt already exists - skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'ScanStartedAt'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [ScanStartedAt] DATETIME2 NULL;
    PRINT 'Column dbo.Appointments.ScanStartedAt added.';
END
ELSE
BEGIN
    PRINT 'Column dbo.Appointments.ScanStartedAt already exists - skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'DeliveredAt'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [DeliveredAt] DATETIME2 NULL;
    PRINT 'Column dbo.Appointments.DeliveredAt added.';
END
ELSE
BEGIN
    PRINT 'Column dbo.Appointments.DeliveredAt already exists - skipped.';
END
GO

-- Filtered index for the overdue query: only active patients (arrived but not
-- delivered) need to be considered. A filtered index keeps it small even at
-- 100k+ rows because >99% of rows fall outside the filter (delivered or never
-- arrived).
--
-- SQL Server requires QUOTED_IDENTIFIER ON for filtered indexes. The DACPAC /
-- sqlcmd default in CI sessions is OFF, which triggers Msg 1934. Setting it
-- here scopes the change to this batch only.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Appointments_Overdue_Active'
      AND object_id = OBJECT_ID(N'[dbo].[Appointments]')
)
BEGIN
    CREATE INDEX [IX_Appointments_Overdue_Active]
        ON [dbo].[Appointments] ([HospitalId], [ArrivedAt])
        WHERE [ArrivedAt] IS NOT NULL AND [DeliveredAt] IS NULL;
    PRINT 'Index IX_Appointments_Overdue_Active created.';
END
ELSE
BEGIN
    PRINT 'Index IX_Appointments_Overdue_Active already exists - skipped.';
END
GO
