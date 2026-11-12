-- ============================================================
-- Migration 112 - A report is never deleted together with its visit
--
-- dbo.DiagnosticReports.AppointmentId was created (migration 12) with
-- ON DELETE CASCADE: deleting an appointment row would silently delete its
-- reports, signed ones included. The API never hard-deletes appointments
-- and its EF model already says Restrict, so this only closes the database-
-- level route: the foreign key becomes NO ACTION (a delete of a visit that
-- has reports is refused instead).
--
-- The key is found by what it links (not by name) so a server whose copy
-- has a different constraint name is handled too.
-- Idempotent - safe to re-run.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

DECLARE @fk sysname, @action NVARCHAR(60);
SELECT TOP (1) @fk = fk.name, @action = fk.delete_referential_action_desc
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
JOIN sys.columns c ON c.object_id = fkc.parent_object_id AND c.column_id = fkc.parent_column_id
WHERE fk.parent_object_id = OBJECT_ID('dbo.DiagnosticReports')
  AND fk.referenced_object_id = OBJECT_ID('dbo.Appointments')
  AND c.name = 'AppointmentId';

IF @fk IS NULL
BEGIN
    ALTER TABLE [dbo].[DiagnosticReports] WITH CHECK
        ADD CONSTRAINT [FK_DiagnosticReports_Appointments]
        FOREIGN KEY ([AppointmentId]) REFERENCES [dbo].[Appointments] ([AppointmentId]) ON DELETE NO ACTION;
    PRINT '  + Created FK_DiagnosticReports_Appointments (NO ACTION)';
END
ELSE IF @action = 'CASCADE'
BEGIN
    EXEC('ALTER TABLE [dbo].[DiagnosticReports] DROP CONSTRAINT [' + @fk + ']');
    ALTER TABLE [dbo].[DiagnosticReports] WITH CHECK
        ADD CONSTRAINT [FK_DiagnosticReports_Appointments]
        FOREIGN KEY ([AppointmentId]) REFERENCES [dbo].[Appointments] ([AppointmentId]) ON DELETE NO ACTION;
    PRINT '  ~ FK_DiagnosticReports_Appointments: ON DELETE CASCADE -> NO ACTION';
END
ELSE PRINT '  = Report -> appointment foreign key is already ' + @action + '.';
GO

PRINT 'Migration 112 applied: reports are no longer cascade-deleted with their visit.';
GO
