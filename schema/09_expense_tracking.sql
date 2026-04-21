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

/* =========================================================
   2. Analytics Views for Expenses
   ========================================================= */

-- 2.1 Daily Expense Matrix
GO
CREATE OR ALTER VIEW dbo.vw_DailyExpenseMatrix
AS
SELECT 
    HospitalId,
    CAST(TransactionDate AS DATE) AS TransactionDate,
    SUM(Amount) AS TotalExpense,
    SUM(TaxAmount) AS TotalTax,
    COUNT(Id) AS ExpenseCount
FROM dbo.Expenses
GROUP BY HospitalId, CAST(TransactionDate AS DATE);
GO

-- 2.2 Monthly Expense Matrix
CREATE OR ALTER VIEW dbo.vw_MonthlyExpenseMatrix
AS
SELECT 
    HospitalId,
    YEAR(TransactionDate) AS TransactionYear,
    MONTH(TransactionDate) AS TransactionMonth,
    FORMAT(TransactionDate, 'MMMM yyyy') AS MonthLabel,
    SUM(Amount) AS MonthlyExpense,
    COUNT(Id) AS ExpenseCount
FROM dbo.Expenses
GROUP BY HospitalId, YEAR(TransactionDate), MONTH(TransactionDate), FORMAT(TransactionDate, 'MMMM yyyy');
GO

-- 2.3 Yearly Expense Matrix
CREATE OR ALTER VIEW dbo.vw_YearlyExpenseMatrix
AS
SELECT 
    HospitalId,
    YEAR(TransactionDate) AS TransactionYear,
    SUM(Amount) AS YearlyExpense
FROM dbo.Expenses
GROUP BY HospitalId, YEAR(TransactionDate);
GO

-- 2.4 Profit & Loss Summary (Integrated View)
CREATE OR ALTER VIEW dbo.vw_ProfitLossSummary
AS
SELECT 
    COALESCE(r.HospitalId, e.HospitalId) AS HospitalId,
    COALESCE(r.TransactionDate, e.TransactionDate) AS TransactionDate,
    ISNULL(r.TotalInvoiced, 0) AS RevenueInvoiced,
    ISNULL(r.TotalCollected, 0) AS RevenueCollected,
    ISNULL(e.TotalExpense, 0) AS ExpenseAmount,
    (ISNULL(r.TotalInvoiced, 0) - ISNULL(e.TotalExpense, 0)) AS NetProfitInvoiced,
    (ISNULL(r.TotalCollected, 0) - ISNULL(e.TotalExpense, 0)) AS NetProfitCollected
FROM dbo.vw_DailyFinancialMatrix r
FULL OUTER JOIN dbo.vw_DailyExpenseMatrix e 
    ON r.HospitalId = e.HospitalId AND r.TransactionDate = e.TransactionDate;
GO

COMMIT;
GO
