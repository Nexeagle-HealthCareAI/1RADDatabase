-- Migration: 40_add_updatedat_to_diagnostic_reports.sql
-- Description: Adds an UpdatedAt column to DiagnosticReports so the client can
--              reliably compare a locally autosaved draft against the server
--              copy. Without a server-side "last saved" timestamp the
--              crash-recovery prompt always treated the local draft as newer.
--              Backfilled from FinalizedAt / CreatedAt for existing rows.

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[DiagnosticReports]') AND name = 'UpdatedAt'
)
BEGIN
    ALTER TABLE [dbo].[DiagnosticReports] ADD [UpdatedAt] DATETIME2 NULL;

    -- Seed existing rows with the best timestamp we have so they aren't all
    -- NULL (which the client would treat as "very old").
    EXEC('UPDATE [dbo].[DiagnosticReports]
          SET [UpdatedAt] = COALESCE([FinalizedAt], [CreatedAt])
          WHERE [UpdatedAt] IS NULL;');

    PRINT 'Column dbo.DiagnosticReports.UpdatedAt added and backfilled successfully.';
END
ELSE
BEGIN
    PRINT 'Column dbo.DiagnosticReports.UpdatedAt already exists — skipped.';
END
GO
