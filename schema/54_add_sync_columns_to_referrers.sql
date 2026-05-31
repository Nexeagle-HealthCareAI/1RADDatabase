-- Migration: 54_add_sync_columns_to_referrers.sql
-- Description: Phase B3 Slice 4 — Referrers offline cache. Backfill
--              UpdatedAt from SYSUTCDATETIME() because Referrer has no
--              CreatedAt column to derive from.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Referrers]') AND name = 'UpdatedAt'
)
BEGIN
    ALTER TABLE [dbo].[Referrers] ADD [UpdatedAt] DATETIME2 NULL;
    -- No CreatedAt to backfill from; stamp every legacy row at migration
    -- time so the first sync pull surfaces them in the delta window.
    EXEC('UPDATE [dbo].[Referrers] SET [UpdatedAt] = SYSUTCDATETIME() WHERE [UpdatedAt] IS NULL;');
    ALTER TABLE [dbo].[Referrers] ALTER COLUMN [UpdatedAt] DATETIME2 NOT NULL;
    PRINT 'Column dbo.Referrers.UpdatedAt added and backfilled.';
END
ELSE PRINT 'Column dbo.Referrers.UpdatedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Referrers]') AND name = 'DeletedAt'
)
BEGIN
    ALTER TABLE [dbo].[Referrers] ADD [DeletedAt] DATETIME2 NULL;
    PRINT 'Column dbo.Referrers.DeletedAt added.';
END
ELSE PRINT 'Column dbo.Referrers.DeletedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Referrers_Hospital_UpdatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[Referrers]')
)
BEGIN
    CREATE INDEX [IX_Referrers_Hospital_UpdatedAt]
        ON [dbo].[Referrers] ([HospitalId], [UpdatedAt]);
    PRINT 'Index IX_Referrers_Hospital_UpdatedAt created.';
END
ELSE PRINT 'Index IX_Referrers_Hospital_UpdatedAt already exists - skipped.';
GO
