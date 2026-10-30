-- ============================================================
-- DROP ALL STAFF / PAYROLL / LEAVE TABLES
-- One-shot reset. Order matters — children first, parents last.
-- Idempotent: skips tables that don't exist.
-- ============================================================

SET NOCOUNT ON;
PRINT '----------------------------------------------------------';
PRINT ' Dropping staff/payroll/leave tables';
PRINT '----------------------------------------------------------';

/* ============================================================
   1. First, drop any FKs from OTHER tables into ours
      Expenses.LinkedDisbursementId → SalaryDisbursements
   ============================================================ */
IF EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_Expenses_LinkedDisbursement'
)
BEGIN
    ALTER TABLE dbo.Expenses DROP CONSTRAINT FK_Expenses_LinkedDisbursement;
    PRINT '  - Dropped FK FK_Expenses_LinkedDisbursement (on Expenses)';
END

-- Also remove the column so Expenses doesn't reference a gone table.
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Expenses' AND COLUMN_NAME = 'LinkedDisbursementId'
)
BEGIN
    -- Drop the index first if it exists.
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Expenses_LinkedDisbursementId'
               AND object_id = OBJECT_ID('dbo.Expenses'))
        DROP INDEX IX_Expenses_LinkedDisbursementId ON dbo.Expenses;

    ALTER TABLE dbo.Expenses DROP COLUMN LinkedDisbursementId;
    PRINT '  - Dropped column dbo.Expenses.LinkedDisbursementId';
END
GO

/* ============================================================
   2. Drop child tables (those with FKs into StaffMembers / SalaryRevisions)
   ============================================================ */
IF OBJECT_ID('dbo.SalaryDisbursements', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.SalaryDisbursements;
    PRINT '  - Dropped dbo.SalaryDisbursements';
END
ELSE PRINT '  = dbo.SalaryDisbursements did not exist.';

IF OBJECT_ID('dbo.SalaryRevisions', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.SalaryRevisions;
    PRINT '  - Dropped dbo.SalaryRevisions';
END
ELSE PRINT '  = dbo.SalaryRevisions did not exist.';

IF OBJECT_ID('dbo.StaffMemberRoles', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.StaffMemberRoles;
    PRINT '  - Dropped dbo.StaffMemberRoles';
END
ELSE PRINT '  = dbo.StaffMemberRoles did not exist.';

IF OBJECT_ID('dbo.StaffDocuments', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.StaffDocuments;
    PRINT '  - Dropped dbo.StaffDocuments';
END
ELSE PRINT '  = dbo.StaffDocuments did not exist.';

IF OBJECT_ID('dbo.StaffAttendance', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.StaffAttendance;
    PRINT '  - Dropped dbo.StaffAttendance';
END
ELSE PRINT '  = dbo.StaffAttendance did not exist.';

IF OBJECT_ID('dbo.StaffLeaveRequests', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.StaffLeaveRequests;
    PRINT '  - Dropped dbo.StaffLeaveRequests';
END
ELSE PRINT '  = dbo.StaffLeaveRequests did not exist.';
GO

/* ============================================================
   3. Drop parent + standalone tables
   ============================================================ */
IF OBJECT_ID('dbo.StaffMembers', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.StaffMembers;
    PRINT '  - Dropped dbo.StaffMembers';
END
ELSE PRINT '  = dbo.StaffMembers did not exist.';

IF OBJECT_ID('dbo.HospitalLeavePolicies', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.HospitalLeavePolicies;
    PRINT '  - Dropped dbo.HospitalLeavePolicies';
END
ELSE PRINT '  = dbo.HospitalLeavePolicies did not exist.';
GO

PRINT '----------------------------------------------------------';
PRINT ' Done. Tables dropped.';
PRINT '----------------------------------------------------------';
