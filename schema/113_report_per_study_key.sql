-- ============================================================
-- Migration 113 - One report per study, and a fast study lookup
--
--   1. IX_DiagnosticReports_AppointmentServiceId: every report open / save /
--      sign looks a report up by (visit, study); there was no index on the
--      study column (migration 57 added the column only).
--   2. UX_DiagnosticReports_Appointment_Service: a visit's study can have only
--      ONE live report. Two screens starting the same study at once could
--      create two rows; the API now answers that clash like a concurrent
--      edit (the second screen takes the saved copy).
--
-- If duplicates already exist the unique rule is NOT created - nothing is
-- deleted. The duplicates are listed so they can be reviewed; re-run this
-- script after resolving them.
-- Idempotent - safe to re-run.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DiagnosticReports_AppointmentServiceId'
               AND object_id = OBJECT_ID('dbo.DiagnosticReports'))
BEGIN
    CREATE INDEX [IX_DiagnosticReports_AppointmentServiceId]
        ON [dbo].[DiagnosticReports] ([AppointmentServiceId])
        WHERE [AppointmentServiceId] IS NOT NULL;
    PRINT '  + IX_DiagnosticReports_AppointmentServiceId';
END
ELSE PRINT '  = IX_DiagnosticReports_AppointmentServiceId already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_DiagnosticReports_Appointment_Service'
               AND object_id = OBJECT_ID('dbo.DiagnosticReports'))
BEGIN
    IF EXISTS (
        SELECT 1 FROM dbo.DiagnosticReports
        WHERE AppointmentServiceId IS NOT NULL AND DeletedAt IS NULL
        GROUP BY AppointmentId, AppointmentServiceId
        HAVING COUNT(*) > 1)
    BEGIN
        PRINT '  ! Duplicate live reports exist for some studies - the one-report-per-study rule was NOT created.';
        PRINT '    Review these rows (keep the signed / newest one, set DeletedAt on the rest), then re-run 113:';
        SELECT r.AppointmentId, r.AppointmentServiceId, r.Id AS ReportId, r.Status, r.CreatedAt, r.UpdatedAt
        FROM dbo.DiagnosticReports r
        JOIN (SELECT AppointmentId, AppointmentServiceId
              FROM dbo.DiagnosticReports
              WHERE AppointmentServiceId IS NOT NULL AND DeletedAt IS NULL
              GROUP BY AppointmentId, AppointmentServiceId
              HAVING COUNT(*) > 1) d
          ON d.AppointmentId = r.AppointmentId AND d.AppointmentServiceId = r.AppointmentServiceId
        WHERE r.DeletedAt IS NULL
        ORDER BY r.AppointmentId, r.AppointmentServiceId, r.CreatedAt;
    END
    ELSE
    BEGIN
        CREATE UNIQUE INDEX [UX_DiagnosticReports_Appointment_Service]
            ON [dbo].[DiagnosticReports] ([AppointmentId], [AppointmentServiceId])
            WHERE [AppointmentServiceId] IS NOT NULL AND [DeletedAt] IS NULL;
        PRINT '  + UX_DiagnosticReports_Appointment_Service (one live report per study)';
    END
END
ELSE PRINT '  = UX_DiagnosticReports_Appointment_Service already exists.';
GO

PRINT 'Migration 113 done.';
GO
