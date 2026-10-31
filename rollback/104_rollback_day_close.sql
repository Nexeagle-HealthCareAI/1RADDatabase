SET QUOTED_IDENTIFIER ON;
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CreditTransactions_Hospital_CreatedAt' AND object_id = OBJECT_ID('dbo.CreditTransactions'))
    DROP INDEX [IX_CreditTransactions_Hospital_CreatedAt] ON [dbo].[CreditTransactions];
GO
IF OBJECT_ID('dbo.DayCloses', 'U') IS NOT NULL DROP TABLE [dbo].[DayCloses];
GO
