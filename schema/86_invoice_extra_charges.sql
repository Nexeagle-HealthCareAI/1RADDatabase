-- Table to store multiple extra charges linked to an invoice
-- Guarded (Oct 2026): originally a bare CREATE, which failed on any re-apply.
-- Behaviour on a fresh database is unchanged.
IF OBJECT_ID('dbo.InvoiceExtraCharges', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[InvoiceExtraCharges] (
        [Id] uniqueidentifier NOT NULL DEFAULT NEWID(),
        [InvoiceId] uniqueidentifier NOT NULL,
        [Reason] nvarchar(max) NOT NULL,
        [Amount] decimal(18,2) NOT NULL,
        [CreatedAt] datetime2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_InvoiceExtraCharges] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_InvoiceExtraCharges_Invoices_InvoiceId] FOREIGN KEY ([InvoiceId]) REFERENCES [dbo].[Invoices] ([Id]) ON DELETE CASCADE
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_InvoiceExtraCharges_InvoiceId'
               AND object_id = OBJECT_ID('dbo.InvoiceExtraCharges'))
    CREATE INDEX [IX_InvoiceExtraCharges_InvoiceId] ON [dbo].[InvoiceExtraCharges] ([InvoiceId]);
GO
