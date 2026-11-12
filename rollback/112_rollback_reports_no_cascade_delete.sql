-- Rollback for migration 112 - restores ON DELETE CASCADE on the report -> appointment key.
-- (Not recommended: it brings back the route that deletes signed reports with their visit.)
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DiagnosticReports_Appointments')
    ALTER TABLE [dbo].[DiagnosticReports] DROP CONSTRAINT [FK_DiagnosticReports_Appointments];
ALTER TABLE [dbo].[DiagnosticReports] WITH CHECK
    ADD CONSTRAINT [FK_DiagnosticReports_Appointments]
    FOREIGN KEY ([AppointmentId]) REFERENCES [dbo].[Appointments] ([AppointmentId]) ON DELETE CASCADE;
GO
PRINT 'Migration 112 rolled back.';
GO
