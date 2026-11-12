-- Rollback for 102. Refund rows (Kind = 'REFUND') stay in place as negative payments;
-- only the guards and the new columns' constraints are removed.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF OBJECT_ID('dbo.TR_Payments_AppendOnly', 'TR') IS NOT NULL DROP TRIGGER [dbo].[TR_Payments_AppendOnly];
GO
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Payments_KindSign')
    ALTER TABLE [dbo].[Payments] DROP CONSTRAINT [CK_Payments_KindSign];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Payments_InvoiceId' AND object_id = OBJECT_ID('dbo.Payments'))
    DROP INDEX [IX_Payments_InvoiceId] ON [dbo].[Payments];
GO
IF COL_LENGTH('dbo.Invoices', 'RowVersion') IS NOT NULL ALTER TABLE [dbo].[Invoices] DROP COLUMN [RowVersion];
GO
IF COL_LENGTH('dbo.Payments', 'RefundOfPaymentId') IS NOT NULL ALTER TABLE [dbo].[Payments] DROP COLUMN [RefundOfPaymentId];
GO
IF COL_LENGTH('dbo.Payments', 'CreatedByUserId') IS NOT NULL ALTER TABLE [dbo].[Payments] DROP COLUMN [CreatedByUserId];
GO
IF COL_LENGTH('dbo.Payments', 'Reason') IS NOT NULL ALTER TABLE [dbo].[Payments] DROP COLUMN [Reason];
GO
IF COL_LENGTH('dbo.Payments', 'Kind') IS NOT NULL
BEGIN
    ALTER TABLE [dbo].[Payments] DROP CONSTRAINT [DF_Payments_Kind];
    ALTER TABLE [dbo].[Payments] DROP COLUMN [Kind];
END
GO
