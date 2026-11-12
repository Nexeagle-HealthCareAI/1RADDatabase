-- ============================================================
-- 119 MONEY, PHASE 3: WHEN AN EXPENSE WAS PAID
-- Mirrors Expense.PaidAt (ApplicationDbContext).
--
-- An expense can be entered as "to pay" and paid later. The cash book counts it on
-- the day the money left (PaidAt), not the day it was entered, and only once paid.
-- Existing paid expenses take their transaction date.
-- Requires 06 (Expenses). Safe to run more than once.
-- Rollback: rollback/119_rollback_expense_paid_at.sql
-- ============================================================
SET NOCOUNT ON;
IF COL_LENGTH('dbo.Expenses', 'PaidAt') IS NULL
    ALTER TABLE dbo.Expenses ADD PaidAt DATETIME2 NULL;
EXEC('UPDATE dbo.Expenses SET PaidAt = TransactionDate WHERE PaidAt IS NULL AND Status = ''Paid''');
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Expenses_Hospital_PaidAt' AND object_id = OBJECT_ID('dbo.Expenses'))
    EXEC('CREATE INDEX IX_Expenses_Hospital_PaidAt ON dbo.Expenses (HospitalId, PaidAt) WHERE PaidAt IS NOT NULL');
PRINT 'Migration 119 applied: Expenses.PaidAt.';
