-- Migration: 48_add_sync_columns_to_patients.sql
-- Description: Phase B1 Slice 2 — extend the offline-first cache from
--              Appointments to Patients. Same shape as migration 47:
--              UpdatedAt for delta-fetch, DeletedAt for tombstone-aware
--              reconciliation, plus a covering index for the sync engine's
--              hot query.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Patients]') AND name = 'UpdatedAt'
)
BEGIN
    ALTER TABLE [dbo].[Patients] ADD [UpdatedAt] DATETIME2 NULL;
    -- Backfill from CreatedAt so legacy rows have a non-null value the
    -- client can treat as "I've seen this state". Without it the first
    -- sync pull would force a full refetch of every patient ever.
    EXEC('UPDATE [dbo].[Patients] SET [UpdatedAt] = [CreatedAt] WHERE [UpdatedAt] IS NULL;');
    ALTER TABLE [dbo].[Patients] ALTER COLUMN [UpdatedAt] DATETIME2 NOT NULL;
    PRINT 'Column dbo.Patients.UpdatedAt added and backfilled.';
END
ELSE PRINT 'Column dbo.Patients.UpdatedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Patients]') AND name = 'DeletedAt'
)
BEGIN
    ALTER TABLE [dbo].[Patients] ADD [DeletedAt] DATETIME2 NULL;
    PRINT 'Column dbo.Patients.DeletedAt added.';
END
ELSE PRINT 'Column dbo.Patients.DeletedAt already exists - skipped.';
GO

-- Delta-fetch index. Sync engine runs
--   WHERE HospitalId = @h AND UpdatedAt > @since
-- on every poll. Composite (HospitalId, UpdatedAt) keeps each pull to a
-- small range scan even at hundreds of thousands of historical patients.
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Patients_Hospital_UpdatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[Patients]')
)
BEGIN
    CREATE INDEX [IX_Patients_Hospital_UpdatedAt]
        ON [dbo].[Patients] ([HospitalId], [UpdatedAt]);
    PRINT 'Index IX_Patients_Hospital_UpdatedAt created.';
END
ELSE PRINT 'Index IX_Patients_Hospital_UpdatedAt already exists - skipped.';
GO
