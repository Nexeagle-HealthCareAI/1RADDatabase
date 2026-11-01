-- ============================================================
-- Migration 102 - Append-only payments with refund rows; Invoice RowVersion
-- (appointments/billing/referral review, Oct 2026: B1, B5, B6, B7)
--
-- Before: refunds, cancellations and "mark free" DELETED Payment rows. Yesterday's
-- closed cash total dropped when today's refund was approved, nothing recorded how
-- or by whom money went back, and wallet-funded payments were never returned.
--
-- After: a Payment row is never deleted or edited. Money going back is its own row:
--   Kind = 'REFUND', Amount < 0, PaymentMethod = how it was returned
--   (CASH / UPI / CARD, or ADVANCE when it is parked in the patient's wallet),
--   CreatedAt = the refund day, CreatedByUserId = who did it, Reason = why.
-- Invoice.PaidAmount = SUM(Payments.Amount) for that invoice.
--
-- Invoices also get a ROWVERSION so two cashiers collecting on the same bill at the
-- same moment can no longer both write PaidAmount (the second save gets a conflict).
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('dbo.Payments', 'Kind') IS NULL
    ALTER TABLE [dbo].[Payments] ADD [Kind] NVARCHAR(20) NOT NULL
        CONSTRAINT [DF_Payments_Kind] DEFAULT (N'PAYMENT');
GO
IF COL_LENGTH('dbo.Payments', 'Reason') IS NULL
    ALTER TABLE [dbo].[Payments] ADD [Reason] NVARCHAR(500) NULL;
GO
IF COL_LENGTH('dbo.Payments', 'CreatedByUserId') IS NULL
    ALTER TABLE [dbo].[Payments] ADD [CreatedByUserId] UNIQUEIDENTIFIER NULL;
GO
IF COL_LENGTH('dbo.Payments', 'RefundOfPaymentId') IS NULL
    ALTER TABLE [dbo].[Payments] ADD [RefundOfPaymentId] UNIQUEIDENTIFIER NULL;
GO

-- A PAYMENT is positive, a REFUND is negative. Nothing else is allowed.
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Payments_KindSign')
    -- WITH NOCHECK: enforced for every new or changed row; existing rows are left as
    -- they are (old data may hold a zero-amount row, which would otherwise stop the deploy).
    ALTER TABLE [dbo].[Payments] WITH NOCHECK ADD CONSTRAINT [CK_Payments_KindSign]
        CHECK (([Kind] = N'PAYMENT' AND [Amount] > 0) OR ([Kind] = N'REFUND' AND [Amount] < 0));
GO

-- Payments are append-only: block UPDATE and DELETE at the database.
IF OBJECT_ID('dbo.TR_Payments_AppendOnly', 'TR') IS NULL
    EXEC('CREATE TRIGGER [dbo].[TR_Payments_AppendOnly] ON [dbo].[Payments]
          AFTER UPDATE, DELETE AS
          BEGIN
              SET NOCOUNT ON;
              IF EXISTS (SELECT 1 FROM deleted)
              BEGIN
                  THROW 51002, ''Payments are append-only. Record a refund row instead of editing or deleting a payment.'', 1;
              END
          END');
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Payments_InvoiceId' AND object_id = OBJECT_ID('dbo.Payments'))
    CREATE INDEX [IX_Payments_InvoiceId] ON [dbo].[Payments] ([InvoiceId]) INCLUDE ([Amount], [Kind], [PaymentMethod]);
GO

IF COL_LENGTH('dbo.Invoices', 'RowVersion') IS NULL
    ALTER TABLE [dbo].[Invoices] ADD [RowVersion] ROWVERSION NOT NULL;
GO

PRINT 'Migration 102 applied: refund rows, append-only payments, Invoices.RowVersion.';
GO
