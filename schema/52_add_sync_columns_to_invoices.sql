-- Migration: 52_add_sync_columns_to_invoices.sql
-- Description: Phase B3 Slice 1 — bring Invoices into the offline cache.
--              Same shape as appointments/patients/reports:
--                UpdatedAt → delta-fetch high-water mark
--                DeletedAt → tombstone for client-side purge
--              Plus a (HospitalId, UpdatedAt) index sized for the sync
--              engine's typical poll pattern.
--
-- ROWVERSION is intentionally NOT added here. Invoice OCC is a B2 Track 3
-- follow-up; the offline-first plumbing doesn't need it.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Invoices]') AND name = 'UpdatedAt'
)
BEGIN
    ALTER TABLE [dbo].[Invoices] ADD [UpdatedAt] DATETIME2 NULL;
    -- Backfill from CreatedAt so legacy rows are visible to the first
    -- ?updatedAfter= pull. Without this they'd never appear in deltas
    -- because "NULL > x" is unknown in SQL Server.
    EXEC('UPDATE [dbo].[Invoices] SET [UpdatedAt] = [CreatedAt] WHERE [UpdatedAt] IS NULL;');
    ALTER TABLE [dbo].[Invoices] ALTER COLUMN [UpdatedAt] DATETIME2 NOT NULL;
    PRINT 'Column dbo.Invoices.UpdatedAt added and backfilled.';
END
ELSE PRINT 'Column dbo.Invoices.UpdatedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Invoices]') AND name = 'DeletedAt'
)
BEGIN
    ALTER TABLE [dbo].[Invoices] ADD [DeletedAt] DATETIME2 NULL;
    PRINT 'Column dbo.Invoices.DeletedAt added.';
END
ELSE PRINT 'Column dbo.Invoices.DeletedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Invoices_Hospital_UpdatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[Invoices]')
)
BEGIN
    CREATE INDEX [IX_Invoices_Hospital_UpdatedAt]
        ON [dbo].[Invoices] ([HospitalId], [UpdatedAt]);
    PRINT 'Index IX_Invoices_Hospital_UpdatedAt created.';
END
ELSE PRINT 'Index IX_Invoices_Hospital_UpdatedAt already exists - skipped.';
GO
