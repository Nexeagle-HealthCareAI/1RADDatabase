-- Migration: 49_add_sync_columns_to_diagnostic_reports.sql
-- Description: Phase B1 Slice 3 — bring DiagnosticReports into the offline
--              cache so radiologists can re-open prior reports for the
--              cached worklist appointments during brief outages.
--
--              UpdatedAt already exists on this table (migration 40), so we
--              only add DeletedAt for tombstone semantics and the
--              (HospitalId, UpdatedAt) sync index.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[DiagnosticReports]') AND name = 'DeletedAt'
)
BEGIN
    ALTER TABLE [dbo].[DiagnosticReports] ADD [DeletedAt] DATETIME2 NULL;
    PRINT 'Column dbo.DiagnosticReports.DeletedAt added.';
END
ELSE PRINT 'Column dbo.DiagnosticReports.DeletedAt already exists - skipped.';
GO

-- Defensive: legacy rows may have UpdatedAt NULL (the column was nullable
-- when added in migration 40). Backfill from FinalizedAt / CreatedAt so
-- the first sync pull doesn't ignore them entirely. Leaving them NULL
-- would mean they never appear in any ?updatedAfter= delta because
-- "NULL > x" is unknown in SQL Server.
EXEC('UPDATE [dbo].[DiagnosticReports]
      SET [UpdatedAt] = COALESCE([FinalizedAt], [CreatedAt], SYSUTCDATETIME())
      WHERE [UpdatedAt] IS NULL;');
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_DiagnosticReports_Hospital_UpdatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[DiagnosticReports]')
)
BEGIN
    CREATE INDEX [IX_DiagnosticReports_Hospital_UpdatedAt]
        ON [dbo].[DiagnosticReports] ([HospitalId], [UpdatedAt]);
    PRINT 'Index IX_DiagnosticReports_Hospital_UpdatedAt created.';
END
ELSE PRINT 'Index IX_DiagnosticReports_Hospital_UpdatedAt already exists - skipped.';
GO
