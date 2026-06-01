-- Migration: 58_appointment_service_reported_at.sql
-- Description: Per-service TAT timestamps for the "time in current stage"
-- pills on the worklist + modality queue.
--
-- Adds two nullable timestamp columns to AppointmentServices:
--   • ReportedAt   — when the diagnostic report was finalised for this
--                    service line. Today we can only infer this from the
--                    row's UpdatedAt, which drifts whenever anything
--                    else on the row changes; with a dedicated column the
--                    "Reported X min ago / Awaiting delivery" pill stays
--                    accurate even after late edits.
--   • CancelledAt  — when the service was withdrawn from the visit.
--                    Currently inferred from DeletedAt (soft-delete) +
--                    Status='CANCELLED', but the two are not identical
--                    (a line can be CANCELLED without being soft-deleted,
--                    e.g. a no-show that we still want on the audit trail).
--
-- Backfill strategy: best-effort, no data loss if we skip rows.
--   • ReportedAt   ← UpdatedAt for rows currently in REPORTED or
--                    DELIVERED state where ReportedAt is null. For
--                    DELIVERED rows we cap at DeliveredAt - 1 second so
--                    the timeline order REPORTED → DELIVERED is
--                    preserved.
--   • CancelledAt  ← UpdatedAt for rows currently in CANCELLED state
--                    where CancelledAt is null.
--
-- Safe to re-run: every step is guarded with IF NOT EXISTS / WHERE.
-- Non-breaking: nullable columns + handlers tolerate missing values.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-------------------------------------------------------------------------------
-- Step 1: Add columns
-------------------------------------------------------------------------------
IF COL_LENGTH('dbo.AppointmentServices', 'ReportedAt') IS NULL
BEGIN
    ALTER TABLE [dbo].[AppointmentServices]
        ADD [ReportedAt] DATETIME2 NULL;
END
GO

IF COL_LENGTH('dbo.AppointmentServices', 'CancelledAt') IS NULL
BEGIN
    ALTER TABLE [dbo].[AppointmentServices]
        ADD [CancelledAt] DATETIME2 NULL;
END
GO

-------------------------------------------------------------------------------
-- Step 2: Backfill ReportedAt for rows already in REPORTED/DELIVERED state
-------------------------------------------------------------------------------
UPDATE s
SET s.ReportedAt = CASE
    WHEN s.Status = 'DELIVERED' AND s.DeliveredAt IS NOT NULL
        THEN DATEADD(SECOND, -1, s.DeliveredAt)
    ELSE s.UpdatedAt
END
FROM [dbo].[AppointmentServices] s
WHERE s.ReportedAt IS NULL
  AND s.Status IN ('REPORTED', 'DELIVERED');
GO

-------------------------------------------------------------------------------
-- Step 3: Backfill CancelledAt for rows already in CANCELLED state
-------------------------------------------------------------------------------
UPDATE [dbo].[AppointmentServices]
SET CancelledAt = UpdatedAt
WHERE CancelledAt IS NULL
  AND Status = 'CANCELLED';
GO
