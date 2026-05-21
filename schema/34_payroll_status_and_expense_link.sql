/* =========================================================
   34 - Payroll Draft/Paid Status + Expense Link

   Adds a Draft/Paid status workflow to salary disbursements,
   and links each disbursement to an auto-generated expense row
   so paid salaries appear in the Finance > Expenses ledger
   (and either HR or Accountant can mark them paid from either side).
   ========================================================= */

/* ---------------------------------------------------------
   1. SalaryDisbursements.Status — Draft (default) | Paid
   --------------------------------------------------------- */
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'SalaryDisbursements'
      AND COLUMN_NAME = 'Status'
)
BEGIN
    ALTER TABLE dbo.SalaryDisbursements
        ADD [Status] NVARCHAR(20) NOT NULL
            CONSTRAINT DF_SalaryDisbursements_Status DEFAULT 'Draft';
    PRINT 'Added column dbo.SalaryDisbursements.Status';
END
ELSE
    PRINT 'Column dbo.SalaryDisbursements.Status already exists — skipped.';
GO

/* ---------------------------------------------------------
   2. Expenses.LinkedDisbursementId — FK to SalaryDisbursements
   --------------------------------------------------------- */
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Expenses'
      AND COLUMN_NAME = 'LinkedDisbursementId'
)
BEGIN
    ALTER TABLE dbo.Expenses
        ADD LinkedDisbursementId UNIQUEIDENTIFIER NULL;
    PRINT 'Added column dbo.Expenses.LinkedDisbursementId';
END
ELSE
    PRINT 'Column dbo.Expenses.LinkedDisbursementId already exists — skipped.';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_Expenses_LinkedDisbursement'
      AND parent_object_id = OBJECT_ID('dbo.Expenses')
)
BEGIN
    ALTER TABLE dbo.Expenses
        ADD CONSTRAINT FK_Expenses_LinkedDisbursement
            FOREIGN KEY (LinkedDisbursementId)
            REFERENCES dbo.SalaryDisbursements(DisbursementId)
            ON DELETE SET NULL;
    PRINT 'Added FK FK_Expenses_LinkedDisbursement';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_Expenses_LinkedDisbursementId'
                 AND object_id = OBJECT_ID('dbo.Expenses'))
    CREATE INDEX IX_Expenses_LinkedDisbursementId
        ON dbo.Expenses (LinkedDisbursementId);
GO
