-- Migration: 43_add_overdue_acknowledgement_to_appointments.sql
-- Description: Adds OverdueAcknowledgedAt + OverdueAcknowledgedBy to
--              Appointments so the SLA bell can be silenced per-patient.
--              Once a user acknowledges an overdue case, it disappears from
--              the bell count + stops the row pulse + stops re-firing
--              desktop notifications. The row is still visible in an
--              "Acknowledged" section of the bell dropdown for audit.
--              Cleared implicitly when the patient is delivered (the row
--              just exits the /overdue results altogether).

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'OverdueAcknowledgedAt'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [OverdueAcknowledgedAt] DATETIME2 NULL;
    PRINT 'Column dbo.Appointments.OverdueAcknowledgedAt added.';
END
ELSE
BEGIN
    PRINT 'Column dbo.Appointments.OverdueAcknowledgedAt already exists - skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'OverdueAcknowledgedBy'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [OverdueAcknowledgedBy] UNIQUEIDENTIFIER NULL;
    PRINT 'Column dbo.Appointments.OverdueAcknowledgedBy added.';
END
ELSE
BEGIN
    PRINT 'Column dbo.Appointments.OverdueAcknowledgedBy already exists - skipped.';
END
GO
