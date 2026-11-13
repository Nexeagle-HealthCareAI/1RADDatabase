-- ============================================================
-- 121 STAFF: WORKING DAYS, HOLIDAYS AND LEAVE BALANCES
-- Mirrors HospitalWorkCalendar, HospitalHoliday, StaffLeaveLedgerEntry and
-- StaffMember.WeeklyOff (ApplicationDbContext).
--
--  • HospitalWorkCalendars — one row per centre: the weekly off days (e.g. 'SUN')
--    and which Saturdays are off ('2_4' = 2nd and 4th, '1_3' = 1st and 3rd).
--    A centre with no row works Monday to Saturday, Sunday off.
--  • HospitalHolidays — the centre's holiday list, one row per date.
--  • StaffMembers.WeeklyOff — a person's own weekly off (e.g. 'TUE' for a
--    radiographer who works Sundays); NULL = the centre's weekly off.
--  • StaffLeaveLedger — leave credits that are not leave taken: opening balance
--    for existing staff, manual corrections, and days carried into a new year.
--    Leave taken still comes from StaffLeaveRequests; quotas from the leave policy.
-- Requires 31 (StaffMembers). Safe to run more than once.
-- Rollback: rollback/121_rollback_work_calendar_leave_ledger.sql
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
SET NOCOUNT ON;

IF OBJECT_ID('dbo.HospitalWorkCalendars', 'U') IS NULL
    CREATE TABLE dbo.HospitalWorkCalendars (
        HospitalId      UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HospitalWorkCalendars PRIMARY KEY,
        WeeklyOff       NVARCHAR(30)  NOT NULL CONSTRAINT DF_HospitalWorkCalendars_WeeklyOff DEFAULT N'SUN',
        SaturdaysOff    NVARCHAR(10)  NULL,
        UpdatedAt       DATETIME2     NOT NULL CONSTRAINT DF_HospitalWorkCalendars_UpdatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedByUserId UNIQUEIDENTIFIER NULL,
        CONSTRAINT FK_HospitalWorkCalendars_Hospital FOREIGN KEY (HospitalId) REFERENCES dbo.Hospitals (HospitalId) ON DELETE CASCADE,
        CONSTRAINT CK_HospitalWorkCalendars_Saturdays CHECK (SaturdaysOff IS NULL OR SaturdaysOff IN (N'2_4', N'1_3'))
    );

IF OBJECT_ID('dbo.HospitalHolidays', 'U') IS NULL
    CREATE TABLE dbo.HospitalHolidays (
        HolidayId       UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HospitalHolidays PRIMARY KEY CONSTRAINT DF_HospitalHolidays_Id DEFAULT NEWID(),
        HospitalId      UNIQUEIDENTIFIER NOT NULL,
        HolidayDate     DATE          NOT NULL,
        Name            NVARCHAR(100) NOT NULL,
        CreatedAt       DATETIME2     NOT NULL CONSTRAINT DF_HospitalHolidays_CreatedAt DEFAULT SYSUTCDATETIME(),
        CreatedByUserId UNIQUEIDENTIFIER NULL,
        CONSTRAINT FK_HospitalHolidays_Hospital FOREIGN KEY (HospitalId) REFERENCES dbo.Hospitals (HospitalId) ON DELETE CASCADE
    );
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_HospitalHolidays_Date' AND object_id = OBJECT_ID('dbo.HospitalHolidays'))
    CREATE UNIQUE INDEX UX_HospitalHolidays_Date ON dbo.HospitalHolidays (HospitalId, HolidayDate);

IF COL_LENGTH('dbo.StaffMembers', 'WeeklyOff') IS NULL
    ALTER TABLE dbo.StaffMembers ADD WeeklyOff NVARCHAR(30) NULL;

IF OBJECT_ID('dbo.StaffLeaveLedger', 'U') IS NULL
    CREATE TABLE dbo.StaffLeaveLedger (
        EntryId         UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_StaffLeaveLedger PRIMARY KEY CONSTRAINT DF_StaffLeaveLedger_Id DEFAULT NEWID(),
        StaffId         UNIQUEIDENTIFIER NOT NULL,
        HospitalId      UNIQUEIDENTIFIER NOT NULL,
        LeaveYear       INT           NOT NULL,
        LeaveType       NVARCHAR(50)  NOT NULL,
        Kind            NVARCHAR(20)  NOT NULL,   -- OPENING | ADJUST | CARRY_IN
        Days            DECIMAL(6,2)  NOT NULL,   -- + adds days, − takes them away
        Note            NVARCHAR(300) NULL,
        CreatedAt       DATETIME2     NOT NULL CONSTRAINT DF_StaffLeaveLedger_CreatedAt DEFAULT SYSUTCDATETIME(),
        CreatedByUserId UNIQUEIDENTIFIER NULL,
        CONSTRAINT FK_StaffLeaveLedger_Staff FOREIGN KEY (StaffId) REFERENCES dbo.StaffMembers (StaffId) ON DELETE CASCADE,
        CONSTRAINT CK_StaffLeaveLedger_Kind CHECK (Kind IN (N'OPENING', N'ADJUST', N'CARRY_IN'))
    );
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StaffLeaveLedger_Year' AND object_id = OBJECT_ID('dbo.StaffLeaveLedger'))
    CREATE INDEX IX_StaffLeaveLedger_Year ON dbo.StaffLeaveLedger (HospitalId, LeaveYear, StaffId);

PRINT 'Migration 121 applied: working days, holidays, leave ledger.';
