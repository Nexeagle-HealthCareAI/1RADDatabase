-- ============================================================
-- PAYROLL DRAFT/PAID STATUS + EXPENSE LINK MIGRATION
-- Run this against your 1RadDb database.
-- Safe to run multiple times — every step is idempotent.
--
-- Adds:
--   1. dbo.SalaryDisbursements.Status        (Draft | Paid)
--   2. dbo.Expenses.LinkedDisbursementId     (FK back to a salary disbursement,
--                                             so paid salaries appear in the ledger)
-- ============================================================

SET NOCOUNT ON;
PRINT '----------------------------------------------------------';
PRINT ' Starting draft/paid status + expense link migration';
PRINT '----------------------------------------------------------';

/* ============================================================
   1. SalaryDisbursements.Status — Draft (default) | Paid
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'SalaryDisbursements'
      AND COLUMN_NAME = 'Status'
)
BEGIN
    ALTER TABLE dbo.SalaryDisbursements
        ADD [Status] NVARCHAR(20) NOT NULL
            CONSTRAINT DF_SalaryDisbursements_Status DEFAULT 'Draft';
    PRINT '  + Added column dbo.SalaryDisbursements.Status (default ''Draft'')';

    -- Existing rows were "implicitly paid" under the old schema, so back-fill them as Paid.
    UPDATE dbo.SalaryDisbursements SET [Status] = 'Paid' WHERE [Status] = 'Draft';
    PRINT '  ↻ Back-filled existing disbursements to Paid (legacy rows were implicitly paid).';
END
ELSE
    PRINT '  = Column dbo.SalaryDisbursements.Status already exists.';
GO

/* ============================================================
   2. Expenses.LinkedDisbursementId — FK to SalaryDisbursements
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Expenses'
      AND COLUMN_NAME = 'LinkedDisbursementId'
)
BEGIN
    ALTER TABLE dbo.Expenses
        ADD LinkedDisbursementId UNIQUEIDENTIFIER NULL;
    PRINT '  + Added column dbo.Expenses.LinkedDisbursementId';
END
ELSE
    PRINT '  = Column dbo.Expenses.LinkedDisbursementId already exists.';
GO

-- Foreign key (SET NULL so deleting a disbursement orphans but does not cascade-delete the expense)
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
    PRINT '  + Added FK FK_Expenses_LinkedDisbursement';
END
ELSE
    PRINT '  = FK FK_Expenses_LinkedDisbursement already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_Expenses_LinkedDisbursementId'
                 AND object_id = OBJECT_ID('dbo.Expenses'))
    CREATE INDEX IX_Expenses_LinkedDisbursementId
        ON dbo.Expenses (LinkedDisbursementId);
GO

PRINT '----------------------------------------------------------';
PRINT ' Migration completed successfully.';
PRINT '----------------------------------------------------------';
