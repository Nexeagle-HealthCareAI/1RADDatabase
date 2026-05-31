-- Migration: 47_add_sync_columns_to_appointments.sql
-- Description: Foundations for the local-first offline cache (Phase B1).
--              Adds the two columns the frontend Sync Engine needs to do
--              proper delta-fetch + tombstone-aware reconciliation:
--
--                UpdatedAt  → wall-clock UTC timestamp of the last write
--                             ANYWHERE in the row. Used by the client to
--                             ask the server "what's changed since I last
--                             pulled?" (?updatedAfter=...). Backfilled to
--                             DateTime (the appointment slot) so legacy
--                             rows have a non-null value; subsequent
--                             saves overwrite via the EF SaveChanges hook.
--
--                DeletedAt  → tombstone. Soft-delete marker. Without this
--                             the client can never tell the difference
--                             between "this row was cancelled" and "this
--                             row was never in my last pull". Existing
--                             GET handlers are filtered to
--                             DeletedAt IS NULL so the legacy code path
--                             is unaffected; the sync delta endpoint
--                             explicitly accepts ?includeDeleted=true.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'UpdatedAt'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [UpdatedAt] DATETIME2 NULL;
    -- Backfill so the next sync pull doesn't decide every legacy row is
    -- "newer than the client" and force a full refetch.
    EXEC('UPDATE [dbo].[Appointments] SET [UpdatedAt] = [DateTime] WHERE [UpdatedAt] IS NULL;');
    ALTER TABLE [dbo].[Appointments] ALTER COLUMN [UpdatedAt] DATETIME2 NOT NULL;
    PRINT 'Column dbo.Appointments.UpdatedAt added and backfilled.';
END
ELSE PRINT 'Column dbo.Appointments.UpdatedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'DeletedAt'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [DeletedAt] DATETIME2 NULL;
    PRINT 'Column dbo.Appointments.DeletedAt added.';
END
ELSE PRINT 'Column dbo.Appointments.DeletedAt already exists - skipped.';
GO

-- Delta-fetch index. The sync endpoint runs
--   WHERE HospitalId = @h AND UpdatedAt > @since
-- on every client pull (one per logged-in user, every 30s when online).
-- A filtered index keeps this small even at scale because the active
-- worklist is a tiny fraction of historical appointments.
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Appointments_Hospital_UpdatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[Appointments]')
)
BEGIN
    CREATE INDEX [IX_Appointments_Hospital_UpdatedAt]
        ON [dbo].[Appointments] ([HospitalId], [UpdatedAt]);
    PRINT 'Index IX_Appointments_Hospital_UpdatedAt created.';
END
ELSE PRINT 'Index IX_Appointments_Hospital_UpdatedAt already exists - skipped.';
GO
