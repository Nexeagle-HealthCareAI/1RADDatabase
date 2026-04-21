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
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT [FK_Expenses_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );

    CREATE INDEX [IX_Expenses_HospitalId_Date] ON dbo.Expenses ([HospitalId], [CreatedAt]);
END

COMMIT;
GO
