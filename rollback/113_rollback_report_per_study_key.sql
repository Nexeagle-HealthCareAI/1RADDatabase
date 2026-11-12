-- Rollback for migration 113.
SET QUOTED_IDENTIFIER ON;
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_DiagnosticReports_Appointment_Service' AND object_id = OBJECT_ID('dbo.DiagnosticReports'))
    DROP INDEX [UX_DiagnosticReports_Appointment_Service] ON [dbo].[DiagnosticReports];
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DiagnosticReports_AppointmentServiceId' AND object_id = OBJECT_ID('dbo.DiagnosticReports'))
    DROP INDEX [IX_DiagnosticReports_AppointmentServiceId] ON [dbo].[DiagnosticReports];
GO
PRINT 'Migration 113 rolled back.';
GO
