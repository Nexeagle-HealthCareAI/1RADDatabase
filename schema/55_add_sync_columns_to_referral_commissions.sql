-- Migration: 55_add_sync_columns_to_referral_commissions.sql
-- Description: Phase B3 Slice 5 — ReferralCommissions offline cache.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[ReferralCommissions]') AND name = 'UpdatedAt'
)
BEGIN
    ALTER TABLE [dbo].[ReferralCommissions] ADD [UpdatedAt] DATETIME2 NULL;
    -- Backfill from TransactionDate (closest analogue to "row creation"
    -- in this table). Ensures the first delta pull includes legacy rows.
    EXEC('UPDATE [dbo].[ReferralCommissions] SET [UpdatedAt] = [TransactionDate] WHERE [UpdatedAt] IS NULL;');
    ALTER TABLE [dbo].[ReferralCommissions] ALTER COLUMN [UpdatedAt] DATETIME2 NOT NULL;
    PRINT 'Column dbo.ReferralCommissions.UpdatedAt added and backfilled.';
END
ELSE PRINT 'Column dbo.ReferralCommissions.UpdatedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[ReferralCommissions]') AND name = 'DeletedAt'
)
BEGIN
    ALTER TABLE [dbo].[ReferralCommissions] ADD [DeletedAt] DATETIME2 NULL;
    PRINT 'Column dbo.ReferralCommissions.DeletedAt added.';
END
ELSE PRINT 'Column dbo.ReferralCommissions.DeletedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_ReferralCommissions_Hospital_UpdatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[ReferralCommissions]')
)
BEGIN
    CREATE INDEX [IX_ReferralCommissions_Hospital_UpdatedAt]
        ON [dbo].[ReferralCommissions] ([HospitalId], [UpdatedAt]);
    PRINT 'Index IX_ReferralCommissions_Hospital_UpdatedAt created.';
END
ELSE PRINT 'Index IX_ReferralCommissions_Hospital_UpdatedAt already exists - skipped.';
GO
