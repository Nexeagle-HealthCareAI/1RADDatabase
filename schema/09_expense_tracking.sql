/* =========================================================
   1Rad / Finance Hub
   DDL Script: Expense Tracking Infrastructure
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;

/* =========================================================
   1. Expenses Table
   ========================================================= */
IF OBJECT_ID('dbo.Expenses', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Expenses (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY CONSTRAINT [DF_Expenses_Id] DEFAULT NEWID(),
        [Description] NVARCHAR(MAX) NOT NULL,
        [Category] NVARCHAR(100) NOT NULL, -- e.g., Maintenance, Staff, Utilities, Reagents
        [Amount] DECIMAL(18, 2) NOT NULL,
        [TaxAmount] DECIMAL(18, 2) DEFAULT 0 NOT NULL,
        [PaymentMode] NVARCHAR(50) NULL, -- e.g., Cash, UPI, Bank Transfer
        [ReferenceNumber] NVARCHAR(100) NULL, -- e.g., Bill No, Transaction ID
        [VendorName] NVARCHAR(200) NULL,
        [CostCenter] NVARCHAR(100) NULL, -- e.g., Radiology, Lab, OPD, Pharmacy
        [Status] NVARCHAR(50) DEFAULT 'Paid' NOT NULL, -- Draft, Pending, Approved, Paid
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [TransactionDate] DATETIME NOT NULL DEFAULT GETUTCDATE(),
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT [FK_Expenses_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );

    CREATE INDEX [IX_Expenses_HospitalId_Audit] ON dbo.Expenses ([HospitalId], [TransactionDate], [CostCenter]);
END

COMMIT;
GO
