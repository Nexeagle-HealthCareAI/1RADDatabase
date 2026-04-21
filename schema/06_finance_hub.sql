/* =========================================================
   1Rad / Finance Hub
   DDL Script: Financial Infrastructure & Analytics Matrix
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;

/* =========================================================
   1. ServiceCharges Table (Registry)
   ========================================================= */
IF OBJECT_ID('dbo.ServiceCharges', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ServiceCharges (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY CONSTRAINT [DF_ServiceCharges_Id] DEFAULT NEWID(),
        [Modality] NVARCHAR(50) NOT NULL,
        [ServiceName] NVARCHAR(255) NOT NULL,
        [Amount] DECIMAL(18, 2) NOT NULL,
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT [FK_ServiceCharges_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );
END

/* =========================================================
   2. Invoices Table
   ========================================================= */
IF OBJECT_ID('dbo.Invoices', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Invoices (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY CONSTRAINT [DF_Invoices_Id] DEFAULT NEWID(),
        [InvoiceId] NVARCHAR(50) NOT NULL, -- Display ID like INV-XXXXXXXX
        [AppointmentId] UNIQUEIDENTIFIER NULL,
        [PatientId] UNIQUEIDENTIFIER NOT NULL,
        [TotalAmount] DECIMAL(18, 2) NOT NULL,
        [PaidAmount] DECIMAL(18, 2) DEFAULT 0 NOT NULL,
        [Status] NVARCHAR(50) NOT NULL, -- PENDING, PAID, PARTIAL
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [MetaData] NVARCHAR(MAX) NULL, -- JSON for audits
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT [FK_Invoices_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId]),
        CONSTRAINT [FK_Invoices_Patients] FOREIGN KEY ([PatientId]) REFERENCES [dbo].[Patients] ([PatientId]),
        CONSTRAINT [FK_Invoices_Appointments] FOREIGN KEY ([AppointmentId]) REFERENCES [dbo].[Appointments] ([AppointmentId])
    );
    CREATE INDEX [IX_Invoices_HospitalId_Status] ON dbo.Invoices ([HospitalId], [Status]);
END

/* =========================================================
   3. InvoiceItems Table
   ========================================================= */
IF OBJECT_ID('dbo.InvoiceItems', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.InvoiceItems (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY CONSTRAINT [DF_InvoiceItems_Id] DEFAULT NEWID(),
        [InvoiceId] UNIQUEIDENTIFIER NOT NULL,
        [Description] NVARCHAR(MAX) NOT NULL,
        [Amount] DECIMAL(18, 2) NOT NULL,
        [Quantity] INT DEFAULT 1 NOT NULL,
        CONSTRAINT [FK_InvoiceItems_Invoices] FOREIGN KEY ([InvoiceId]) REFERENCES [dbo].[Invoices] ([Id]) ON DELETE CASCADE
    );
END

/* =========================================================
   4. Payments Table
   ========================================================= */
IF OBJECT_ID('dbo.Payments', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Payments (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY CONSTRAINT [DF_Payments_Id] DEFAULT NEWID(),
        [InvoiceId] UNIQUEIDENTIFIER NOT NULL,
        [Amount] DECIMAL(18, 2) NOT NULL,
        [PaymentMethod] NVARCHAR(50) NOT NULL, -- CASH, UPI, CARD
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT [FK_Payments_Invoices] FOREIGN KEY ([InvoiceId]) REFERENCES [dbo].[Invoices] ([Id]),
        CONSTRAINT [FK_Payments_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );
END

/* =========================================================
   5. Analytics Matrix Views
   ========================================================= */

-- 5.1 Daily Matrix
GO
CREATE OR ALTER VIEW dbo.vw_DailyFinancialMatrix
AS
SELECT 
    HospitalId,
    CAST(CreatedAt AS DATE) AS TransactionDate,
    SUM(TotalAmount) AS TotalInvoiced,
    SUM(PaidAmount) AS TotalCollected,
    SUM(TotalAmount - PaidAmount) AS TotalPending,
    CASE WHEN SUM(TotalAmount) > 0 THEN (SUM(PaidAmount) / SUM(TotalAmount)) * 100 ELSE 0 END AS RealizationRate,
    COUNT(Id) AS InvoiceCount
FROM dbo.Invoices
GROUP BY HospitalId, CAST(CreatedAt AS DATE);
GO

-- 5.2 Monthly Matrix
CREATE OR ALTER VIEW dbo.vw_MonthlyFinancialMatrix
AS
SELECT 
    HospitalId,
    YEAR(CreatedAt) AS TransactionYear,
    MONTH(CreatedAt) AS TransactionMonth,
    FORMAT(CreatedAt, 'MMMM yyyy') AS MonthLabel,
    SUM(TotalAmount) AS MonthlyInvoiced,
    SUM(PaidAmount) AS MonthlyCollected,
    SUM(TotalAmount - PaidAmount) AS MonthlyPending,
    CASE WHEN SUM(TotalAmount) > 0 THEN (SUM(PaidAmount) / SUM(TotalAmount)) * 100 ELSE 0 END AS RealizationRate
FROM dbo.Invoices
GROUP BY HospitalId, YEAR(CreatedAt), MONTH(CreatedAt), FORMAT(CreatedAt, 'MMMM yyyy');
GO

-- 5.3 Yearly Matrix
CREATE OR ALTER VIEW dbo.vw_YearlyFinancialMatrix
AS
SELECT 
    HospitalId,
    YEAR(CreatedAt) AS TransactionYear,
    SUM(TotalAmount) AS YearlyInvoiced,
    SUM(PaidAmount) AS YearlyCollected,
    SUM(TotalAmount - PaidAmount) AS YearlyPending,
    CASE WHEN SUM(TotalAmount) > 0 THEN (SUM(PaidAmount) / SUM(TotalAmount)) * 100 ELSE 0 END AS RealizationRate
FROM dbo.Invoices
GROUP BY HospitalId, YEAR(CreatedAt);
GO

-- 5.4 Revenue Leakage Report
CREATE OR ALTER VIEW dbo.vw_RevenueLeakageReport
AS
SELECT 
    i.HospitalId,
    i.InvoiceId,
    p.FullName AS PatientName,
    i.TotalAmount,
    i.PaidAmount,
    (i.TotalAmount - i.PaidAmount) AS LeakageAmount,
    i.Status,
    i.CreatedAt AS InvoiceDate
FROM dbo.Invoices i
JOIN dbo.Patients p ON i.PatientId = p.PatientId
WHERE i.Status <> 'PAID';
GO

COMMIT;
