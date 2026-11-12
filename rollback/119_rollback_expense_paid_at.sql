-- Rollback for 119_expense_paid_at.sql. Roll the API back FIRST.
SET NOCOUNT ON;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Expenses_Hospital_PaidAt' AND object_id = OBJECT_ID('dbo.Expenses'))
    DROP INDEX IX_Expenses_Hospital_PaidAt ON dbo.Expenses;
IF COL_LENGTH('dbo.Expenses', 'PaidAt') IS NOT NULL ALTER TABLE dbo.Expenses DROP COLUMN PaidAt;
PRINT 'Rolled back 119';
