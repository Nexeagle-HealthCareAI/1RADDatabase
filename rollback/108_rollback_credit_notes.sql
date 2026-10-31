SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('dbo.TR_CreditNotes_AppendOnly', 'TR') IS NOT NULL DROP TRIGGER [dbo].[TR_CreditNotes_AppendOnly];
GO
IF OBJECT_ID('dbo.CreditNotes', 'U') IS NOT NULL DROP TABLE [dbo].[CreditNotes];
GO
DELETE FROM [dbo].[SequenceCounters] WHERE [CounterKey] LIKE 'CN[_]FY[_]%' OR [CounterKey] LIKE 'RV[_]FY[_]%';
GO
