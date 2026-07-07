-- Migration: 83_referrer_merge.sql
-- Description: Adds MergedIntoId to Referrers to support reversible "Virtual Merges"
--              of duplicate referral partners without data loss.

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE name = 'MergedIntoId' 
                 AND object_id = OBJECT_ID(N'[dbo].[Referrers]'))
BEGIN
    ALTER TABLE [dbo].[Referrers] ADD [MergedIntoId] UNIQUEIDENTIFIER NULL;
    
    ALTER TABLE [dbo].[Referrers]
        ADD CONSTRAINT [FK_Referrers_MergedInto] 
        FOREIGN KEY ([MergedIntoId]) REFERENCES [dbo].[Referrers]([ReferrerId]);

    PRINT 'Column dbo.Referrers.MergedIntoId added.';
END
ELSE
BEGIN
    PRINT 'Column dbo.Referrers.MergedIntoId already exists - skipped.';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes 
               WHERE name = 'IX_Referrers_MergedIntoId' 
                 AND object_id = OBJECT_ID(N'[dbo].[Referrers]'))
BEGIN
    CREATE INDEX [IX_Referrers_MergedIntoId] ON [dbo].[Referrers] ([MergedIntoId]);
    PRINT 'Index IX_Referrers_MergedIntoId created.';
END
ELSE
BEGIN
    PRINT 'Index IX_Referrers_MergedIntoId already exists - skipped.';
END
GO
