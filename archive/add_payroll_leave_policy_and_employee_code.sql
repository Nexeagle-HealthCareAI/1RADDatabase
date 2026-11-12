-- ============================================================
-- PAYROLL + LEAVE POLICY + EMPLOYEE CODE MIGRATION
-- Run this against your 1RadDb database.
-- Safe to run multiple times — every step is idempotent.
--
-- Adds:
--   1. dbo.StaffMembers.EmployeeCode  (column + unique filtered index)
--   2. dbo.SalaryRevisions             (table + indexes)
--   3. dbo.SalaryDisbursements         (table + unique index on Staff,Month)
--   4. dbo.HospitalLeavePolicies       (table + unique index on HospitalId)
-- ============================================================

-- Required for the filtered unique index on EmployeeCode (SQL Server rule).
-- Must be set at the start of the batch, before any CREATE INDEX with a WHERE clause.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

SET NOCOUNT ON;
PRINT '----------------------------------------------------------';
PRINT ' Starting payroll + leave policy migration';
PRINT '----------------------------------------------------------';

/* ============================================================
   1. StaffMembers.EmployeeCode — "EMP-NNNN" per hospital
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'StaffMembers'
      AND COLUMN_NAME = 'EmployeeCode'
)
BEGIN
    ALTER TABLE dbo.StaffMembers
        ADD EmployeeCode NVARCHAR(20) NULL;
    PRINT '  + Added column dbo.StaffMembers.EmployeeCode';
END
ELSE
    PRINT '  = Column dbo.StaffMembers.EmployeeCode already exists.';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_StaffMembers_HospitalId_EmployeeCode'
      AND object_id = OBJECT_ID('dbo.StaffMembers')
)
BEGIN
    CREATE UNIQUE INDEX UX_StaffMembers_HospitalId_EmployeeCode
        ON dbo.StaffMembers (HospitalId, EmployeeCode)
        WHERE EmployeeCode IS NOT NULL;
    PRINT '  + Created unique filtered index UX_StaffMembers_HospitalId_EmployeeCode';
END
ELSE
    PRINT '  = Index UX_StaffMembers_HospitalId_EmployeeCode already exists.';
GO

/* ============================================================
   2. SalaryRevisions — salary structure history per staff
   ============================================================ */
IF OBJECT_ID('dbo.SalaryRevisions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SalaryRevisions
    (
        RevisionId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_SalaryRevisions PRIMARY KEY
            CONSTRAINT DF_SalaryRevisions_RevisionId DEFAULT NEWID(),

        StaffId    UNIQUEIDENTIFIER NOT NULL,
        HospitalId UNIQUEIDENTIFIER NOT NULL,

        EffectiveFrom DATE NOT NULL,

        BasicPay        DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_Basic   DEFAULT 0,
        Hra             DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_Hra     DEFAULT 0,
        Travel          DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_Travel  DEFAULT 0,
        OtherAllowances DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_OtherA  DEFAULT 0,
        PfDeduction     DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_Pf      DEFAULT 0,
        Tds             DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_Tds     DEFAULT 0,
        OtherDeductions DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_OtherD  DEFAULT 0,

        Note            NVARCHAR(500) NULL,

        CreatedAt       DATETIME2 NOT NULL
            CONSTRAINT DF_SalaryRevisions_CreatedAt DEFAULT GETUTCDATE(),
        CreatedByUserId UNIQUEIDENTIFIER NULL,

        CONSTRAINT FK_SalaryRevisions_StaffMembers
            FOREIGN KEY (StaffId)
            REFERENCES dbo.StaffMembers(StaffId)
            ON DELETE CASCADE,

        CONSTRAINT FK_SalaryRevisions_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId)
    );
    PRINT '  + Created table dbo.SalaryRevisions';
END
ELSE
    PRINT '  = Table dbo.SalaryRevisions already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalaryRevisions_Staff_Effective'
               AND object_id = OBJECT_ID('dbo.SalaryRevisions'))
    CREATE INDEX IX_SalaryRevisions_Staff_Effective
        ON dbo.SalaryRevisions (StaffId, EffectiveFrom);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalaryRevisions_HospitalId'
               AND object_id = OBJECT_ID('dbo.SalaryRevisions'))
    CREATE INDEX IX_SalaryRevisions_HospitalId
        ON dbo.SalaryRevisions (HospitalId);
GO

/* ============================================================
   3. SalaryDisbursements — monthly payouts (one per staff,month)
   ============================================================ */
IF OBJECT_ID('dbo.SalaryDisbursements', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SalaryDisbursements
    (
        DisbursementId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_SalaryDisbursements PRIMARY KEY
            CONSTRAINT DF_SalaryDisbursements_DisbursementId DEFAULT NEWID(),

        StaffId    UNIQUEIDENTIFIER NOT NULL,
        HospitalId UNIQUEIDENTIFIER NOT NULL,
        RevisionId UNIQUEIDENTIFIER NULL,

        [Month] NVARCHAR(7) NOT NULL,   -- "YYYY-MM"

        GrossPay       DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_Gross    DEFAULT 0,
        NetPay         DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_Net      DEFAULT 0,
        StructureGross DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_StrGross DEFAULT 0,
        StructureNet   DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_StrNet   DEFAULT 0,

        LwpDays          DECIMAL(5,2)  NOT NULL CONSTRAINT DF_SalaryDisbursements_LwpDays      DEFAULT 0,
        LwpDeduction     DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_LwpDeduction DEFAULT 0,
        PerDayRate       DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_PerDay       DEFAULT 0,
        PaidLeaveInMonth INT           NOT NULL CONSTRAINT DF_SalaryDisbursements_PaidLeave    DEFAULT 0,
        LwpLeaveInMonth  INT           NOT NULL CONSTRAINT DF_SalaryDisbursements_LwpLeave     DEFAULT 0,

        AttendanceJson NVARCHAR(2000) NULL,

        PaymentMode NVARCHAR(20) NOT NULL
            CONSTRAINT DF_SalaryDisbursements_PaymentMode DEFAULT 'bank',
        [Reference] NVARCHAR(200) NULL,
        PaidOnDate  DATE NOT NULL,
        Notes       NVARCHAR(1000) NULL,

        CreatedAt       DATETIME2 NOT NULL
            CONSTRAINT DF_SalaryDisbursements_CreatedAt DEFAULT GETUTCDATE(),
        CreatedByUserId UNIQUEIDENTIFIER NULL,

        CONSTRAINT FK_SalaryDisbursements_StaffMembers
            FOREIGN KEY (StaffId)
            REFERENCES dbo.StaffMembers(StaffId)
            ON DELETE CASCADE,

        CONSTRAINT FK_SalaryDisbursements_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId),

        CONSTRAINT FK_SalaryDisbursements_Revision
            FOREIGN KEY (RevisionId)
            REFERENCES dbo.SalaryRevisions(RevisionId)
            ON DELETE SET NULL
    );
    PRINT '  + Created table dbo.SalaryDisbursements';
END
ELSE
    PRINT '  = Table dbo.SalaryDisbursements already exists.';
GO

-- One disbursal per staff per month
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_SalaryDisbursements_Staff_Month'
               AND object_id = OBJECT_ID('dbo.SalaryDisbursements'))
    CREATE UNIQUE INDEX UX_SalaryDisbursements_Staff_Month
        ON dbo.SalaryDisbursements (StaffId, [Month]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalaryDisbursements_HospitalId'
               AND object_id = OBJECT_ID('dbo.SalaryDisbursements'))
    CREATE INDEX IX_SalaryDisbursements_HospitalId
        ON dbo.SalaryDisbursements (HospitalId);
GO

/* ============================================================
   4. HospitalLeavePolicies — one row per hospital
   ============================================================ */
IF OBJECT_ID('dbo.HospitalLeavePolicies', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.HospitalLeavePolicies
    (
        PolicyId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_HospitalLeavePolicies PRIMARY KEY
            CONSTRAINT DF_HospitalLeavePolicies_PolicyId DEFAULT NEWID(),

        HospitalId UNIQUEIDENTIFIER NOT NULL,

        LeaveTypesJson NVARCHAR(4000) NOT NULL
            CONSTRAINT DF_HospitalLeavePolicies_LeaveTypesJson DEFAULT N'[]',

        UpdatedAt       DATETIME2 NOT NULL
            CONSTRAINT DF_HospitalLeavePolicies_UpdatedAt DEFAULT GETUTCDATE(),
        UpdatedByUserId UNIQUEIDENTIFIER NULL,

        CONSTRAINT FK_HospitalLeavePolicies_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId)
            ON DELETE CASCADE
    );
    PRINT '  + Created table dbo.HospitalLeavePolicies';
END
ELSE
    PRINT '  = Table dbo.HospitalLeavePolicies already exists.';
GO

-- One policy per hospital
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_HospitalLeavePolicies_HospitalId'
               AND object_id = OBJECT_ID('dbo.HospitalLeavePolicies'))
    CREATE UNIQUE INDEX UX_HospitalLeavePolicies_HospitalId
        ON dbo.HospitalLeavePolicies (HospitalId);
GO

PRINT '----------------------------------------------------------';
PRINT ' Migration completed successfully.';
PRINT '----------------------------------------------------------';
