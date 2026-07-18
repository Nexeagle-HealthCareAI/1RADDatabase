-- Table to store multiple extra charges linked to an invoice
CREATE TABLE [InvoiceExtraCharges] (
    [Id] uniqueidentifier NOT NULL DEFAULT NEWID(),
    [InvoiceId] uniqueidentifier NOT NULL,
    [Reason] nvarchar(max) NOT NULL,
    [Amount] decimal(18,2) NOT NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_InvoiceExtraCharges] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_InvoiceExtraCharges_Invoices_InvoiceId] FOREIGN KEY ([InvoiceId]) REFERENCES [Invoices] ([Id]) ON DELETE CASCADE
);
GO

CREATE INDEX [IX_InvoiceExtraCharges_InvoiceId] ON [InvoiceExtraCharges] ([InvoiceId]);
GO
