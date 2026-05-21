/* =========================================================
   32 - Payroll (Salary Revisions + Disbursements) + Employee Code

   Adds a per-hospital sequential employee code on StaffMembers,
   plus two new tables that back the Payroll feature on the
   Staff & Payroll page (salary structure revisions and monthly
   disbursements with payment metadata).
   ========================================================= */

/* ---------------------------------------------------------
   1. StaffMembers.EmployeeCode — human-readable HR code
      Format: "EMP-NNNN" (4-digit, padded). Unique per hospital.
   --------------------------------------------------------- */
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'StaffMembers'
      AND COLUMN_NAME = 'EmployeeCode'
)
BEGIN
    ALTER TABLE dbo.StaffMembers
        ADD EmployeeCode NVARCHAR(20) NULL;
    PRINT 'Added column dbo.StaffMembers.EmployeeCode';
END
ELSE
    PRINT 'Column dbo.StaffMembers.EmployeeCode already exists — skipped.';
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
    PRINT 'Created unique filtered index UX_StaffMembers_HospitalId_EmployeeCode';
END
GO

/* ---------------------------------------------------------
   2. SalaryRevisions — appraisal/structure history per staff
      The "active" revision for any date is the latest one
      whose EffectiveFrom <= that date.
   --------------------------------------------------------- */
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

        -- Earnings
        BasicPay        DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_Basic   DEFAULT 0,
        Hra             DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_Hra     DEFAULT 0,
        Travel          DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_Travel  DEFAULT 0,
        OtherAllowances DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_OtherA  DEFAULT 0,

        -- Deductions
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
    PRINT 'Created table dbo.SalaryRevisions';
END
ELSE
    PRINT 'Table dbo.SalaryRevisions already exists — skipped.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_SalaryRevisions_Staff_Effective'
               AND object_id = OBJECT_ID('dbo.SalaryRevisions'))
    CREATE INDEX IX_SalaryRevisions_Staff_Effective
        ON dbo.SalaryRevisions (StaffId, EffectiveFrom);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_SalaryRevisions_HospitalId'
               AND object_id = OBJECT_ID('dbo.SalaryRevisions'))
    CREATE INDEX IX_SalaryRevisions_HospitalId
        ON dbo.SalaryRevisions (HospitalId);
GO

/* ---------------------------------------------------------
   3. SalaryDisbursements — monthly payouts per staff
      Idempotent: one row per (StaffId, Month).
      Captures the structure snapshot + LWP detail + payment metadata.
   --------------------------------------------------------- */
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

        -- "YYYY-MM" — the pay-period month
        [Month] NVARCHAR(7) NOT NULL,

        -- Pay snapshot (after LWP applied)
        GrossPay DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_Gross DEFAULT 0,
        NetPay   DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_Net   DEFAULT 0,

        -- Structure snapshot (before LWP)
        StructureGross DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_StrGross DEFAULT 0,
        StructureNet   DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_StrNet   DEFAULT 0,

        -- LWP detail
        LwpDays          DECIMAL(5,2)  NOT NULL CONSTRAINT DF_SalaryDisbursements_LwpDays      DEFAULT 0,
        LwpDeduction     DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_LwpDeduction DEFAULT 0,
        PerDayRate       DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisbursements_PerDay       DEFAULT 0,
        PaidLeaveInMonth INT           NOT NULL CONSTRAINT DF_SalaryDisbursements_PaidLeave    DEFAULT 0,
        LwpLeaveInMonth  INT           NOT NULL CONSTRAINT DF_SalaryDisbursements_LwpLeave     DEFAULT 0,

        -- JSON snapshot of attendance counts (present, absent, halfday, late, leave)
        AttendanceJson NVARCHAR(2000) NULL,

        -- Payment metadata
        PaymentMode NVARCHAR(20) NOT NULL
            CONSTRAINT DF_SalaryDisbursements_PaymentMode DEFAULT 'bank',
        -- Values: 'bank' | 'cash' | 'upi' | 'cheque'

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
    PRINT 'Created table dbo.SalaryDisbursements';
END
ELSE
    PRINT 'Table dbo.SalaryDisbursements already exists — skipped.';
GO

-- One disbursal per staff per month
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'UX_SalaryDisbursements_Staff_Month'
               AND object_id = OBJECT_ID('dbo.SalaryDisbursements'))
    CREATE UNIQUE INDEX UX_SalaryDisbursements_Staff_Month
        ON dbo.SalaryDisbursements (StaffId, [Month]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_SalaryDisbursements_HospitalId'
               AND object_id = OBJECT_ID('dbo.SalaryDisbursements'))
    CREATE INDEX IX_SalaryDisbursements_HospitalId
        ON dbo.SalaryDisbursements (HospitalId);
GO
