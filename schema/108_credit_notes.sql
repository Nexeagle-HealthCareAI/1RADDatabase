-- ============================================================
-- Migration 108 - CreditNotes: credit notes and refund vouchers (review B6/B10)
-- Issued by the API whenever a bill that had money on it is lowered, made free,
-- cancelled or deleted (CREDIT_NOTE, "CN2627-00001"), or when money is handed back
-- on a bill whose value did not change (REFUND_VOUCHER, "RV2627-00001").
-- Numbers come from dbo.SequenceCounters (keys CN_FY_2026-27 / RV_FY_2026-27).
-- Rows are append-only: the trigger below refuses UPDATE of the amounts and DELETE.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF OBJECT_ID('dbo.CreditNotes', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[CreditNotes] (
        [Id]              UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_CreditNotes_Id] DEFAULT (NEWID()),
        [HospitalId]      UNIQUEIDENTIFIER NOT NULL,
        [Kind]            NVARCHAR(20)     NOT NULL,
        [Number]          NVARCHAR(16)     NOT NULL,
        [FinancialYear]   NVARCHAR(7)      NOT NULL,
        [InvoiceId]       UNIQUEIDENTIFIER NOT NULL,
        [InvoiceNumber]   NVARCHAR(50)     NOT NULL,
        [InvoiceDate]     DATETIME2        NOT NULL,
        [PatientId]       UNIQUEIDENTIFIER NOT NULL,
        [PatientName]     NVARCHAR(200)    NULL,
        [Amount]          DECIMAL(18,2)    NOT NULL,
        [TaxableValue]    DECIMAL(18,2)    NOT NULL,
        [TaxAmount]       DECIMAL(18,2)    NOT NULL,
        [RefundedAmount]  DECIMAL(18,2)    NOT NULL CONSTRAINT [DF_CreditNotes_RefundedAmount] DEFAULT (0),
        [RefundModes]     NVARCHAR(100)    NULL,
        [BillTotalBefore] DECIMAL(18,2)    NOT NULL,
        [BillTotalAfter]  DECIMAL(18,2)    NOT NULL,
        [Reason]          NVARCHAR(500)    NOT NULL,
        [CreatedByUserId] UNIQUEIDENTIFIER NULL,
        [CreatedAt]       DATETIME2        NOT NULL,
        CONSTRAINT [PK_CreditNotes] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_CreditNotes_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId]),
        CONSTRAINT [FK_CreditNotes_Invoices] FOREIGN KEY ([InvoiceId]) REFERENCES [dbo].[Invoices] ([Id]),
        CONSTRAINT [CK_CreditNotes_Kind] CHECK ([Kind] IN ('CREDIT_NOTE', 'REFUND_VOUCHER')),
        CONSTRAINT [CK_CreditNotes_Amount] CHECK ([Amount] > 0 AND [RefundedAmount] >= 0)
    );
    CREATE UNIQUE INDEX [IX_CreditNotes_HospitalId_Number] ON [dbo].[CreditNotes] ([HospitalId], [Number]);
    CREATE INDEX [IX_CreditNotes_HospitalId_CreatedAt] ON [dbo].[CreditNotes] ([HospitalId], [CreatedAt]);
    CREATE INDEX [IX_CreditNotes_InvoiceId] ON [dbo].[CreditNotes] ([InvoiceId]);
END
GO
-- Issued documents never change. The one exception is the API recording the
-- refund on a credit note raised a moment earlier in the same operation
-- (RefundedAmount / RefundModes only).
CREATE OR ALTER TRIGGER [dbo].[TR_CreditNotes_AppendOnly] ON [dbo].[CreditNotes]
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        RAISERROR('Credit notes cannot be deleted.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    IF EXISTS (
        SELECT 1 FROM inserted i JOIN deleted d ON d.[Id] = i.[Id]
        WHERE i.[Number] <> d.[Number] OR i.[Amount] <> d.[Amount] OR i.[TaxableValue] <> d.[TaxableValue]
           OR i.[TaxAmount] <> d.[TaxAmount] OR i.[InvoiceId] <> d.[InvoiceId] OR i.[Kind] <> d.[Kind]
           OR i.[CreatedAt] <> d.[CreatedAt] OR i.[HospitalId] <> d.[HospitalId])
    BEGIN
        RAISERROR('Credit notes cannot be changed once issued.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO
PRINT 'Migration 108 applied: CreditNotes.';
GO
