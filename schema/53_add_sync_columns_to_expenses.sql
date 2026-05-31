-- Migration: 53_add_sync_columns_to_expenses.sql
-- Description: Phase B3 Slice 3 — Expenses offline cache. Same pattern as
--              Invoices (migration 52). Backfill UpdatedAt from CreatedAt.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Expenses]') AND name = 'UpdatedAt'
)
BEGIN
    ALTER TABLE [dbo].[Expenses] ADD [UpdatedAt] DATETIME2 NULL;
    EXEC('UPDATE [dbo].[Expenses] SET [UpdatedAt] = [CreatedAt] WHERE [UpdatedAt] IS NULL;');
    ALTER TABLE [dbo].[Expenses] ALTER COLUMN [UpdatedAt] DATETIME2 NOT NULL;
    PRINT 'Column dbo.Expenses.UpdatedAt added and backfilled.';
END
ELSE PRINT 'Column dbo.Expenses.UpdatedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Expenses]') AND name = 'DeletedAt'
)
BEGIN
    ALTER TABLE [dbo].[Expenses] ADD [DeletedAt] DATETIME2 NULL;
    PRINT 'Column dbo.Expenses.DeletedAt added.';
END
ELSE PRINT 'Column dbo.Expenses.DeletedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Expenses_Hospital_UpdatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[Expenses]')
)
BEGIN
    CREATE INDEX [IX_Expenses_Hospital_UpdatedAt]
        ON [dbo].[Expenses] ([HospitalId], [UpdatedAt]);
    PRINT 'Index IX_Expenses_Hospital_UpdatedAt created.';
END
ELSE PRINT 'Index IX_Expenses_Hospital_UpdatedAt already exists - skipped.';
GO
