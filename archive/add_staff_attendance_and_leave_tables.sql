-- ============================================================
-- STAFF ATTENDANCE + LEAVE REQUESTS MIGRATION
-- Run this against your 1RadDb database.
-- Safe to run multiple times — every step is idempotent.
-- ============================================================

SET NOCOUNT ON;
PRINT '----------------------------------------------------------';
PRINT ' Starting attendance + leave tables migration';
PRINT '----------------------------------------------------------';

/* ============================================================
   1. dbo.StaffAttendance — one row per (staff, date)
   ============================================================ */
IF OBJECT_ID('dbo.StaffAttendance', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.StaffAttendance
    (
        AttendanceId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_StaffAttendance PRIMARY KEY
            CONSTRAINT DF_StaffAttendance_AttendanceId DEFAULT NEWID(),

        StaffId    UNIQUEIDENTIFIER NOT NULL,
        HospitalId UNIQUEIDENTIFIER NOT NULL,

        AttendanceDate DATE NOT NULL,

        [Status] NVARCHAR(20) NOT NULL
            CONSTRAINT DF_StaffAttendance_Status DEFAULT 'present',

        Note NVARCHAR(500) NULL,

        MarkedByUserId UNIQUEIDENTIFIER NULL,
        MarkedAt       DATETIME2 NOT NULL
            CONSTRAINT DF_StaffAttendance_MarkedAt DEFAULT GETUTCDATE(),

        CONSTRAINT FK_StaffAttendance_StaffMembers
            FOREIGN KEY (StaffId)
            REFERENCES dbo.StaffMembers(StaffId)
            ON DELETE CASCADE,

        CONSTRAINT FK_StaffAttendance_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId)
    );
    PRINT '  + Created table dbo.StaffAttendance';
END
ELSE
    PRINT '  = Table dbo.StaffAttendance already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_StaffAttendance_Staff_Date'
               AND object_id = OBJECT_ID('dbo.StaffAttendance'))
BEGIN
    CREATE UNIQUE INDEX UX_StaffAttendance_Staff_Date
        ON dbo.StaffAttendance (StaffId, AttendanceDate);
    PRINT '  + Created unique index UX_StaffAttendance_Staff_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StaffAttendance_Hospital_Date'
               AND object_id = OBJECT_ID('dbo.StaffAttendance'))
    CREATE INDEX IX_StaffAttendance_Hospital_Date
        ON dbo.StaffAttendance (HospitalId, AttendanceDate);
GO

/* ============================================================
   2. dbo.StaffLeaveRequests — leave applications
   ============================================================ */
IF OBJECT_ID('dbo.StaffLeaveRequests', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.StaffLeaveRequests
    (
        LeaveRequestId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_StaffLeaveRequests PRIMARY KEY
            CONSTRAINT DF_StaffLeaveRequests_LeaveRequestId DEFAULT NEWID(),

        StaffId    UNIQUEIDENTIFIER NOT NULL,
        HospitalId UNIQUEIDENTIFIER NOT NULL,

        LeaveType  NVARCHAR(100) NOT NULL,
        FromDate   DATE NOT NULL,
        ToDate     DATE NOT NULL,
        Days       INT  NOT NULL,
        Reason     NVARCHAR(1000) NULL,

        [Status]   NVARCHAR(20) NOT NULL
            CONSTRAINT DF_StaffLeaveRequests_Status DEFAULT 'pending',

        AppliedOn        DATETIME2 NOT NULL
            CONSTRAINT DF_StaffLeaveRequests_AppliedOn DEFAULT GETUTCDATE(),
        ReviewedByUserId UNIQUEIDENTIFIER NULL,
        ReviewedAt       DATETIME2 NULL,

        CONSTRAINT FK_StaffLeaveRequests_StaffMembers
            FOREIGN KEY (StaffId)
            REFERENCES dbo.StaffMembers(StaffId)
            ON DELETE CASCADE,

        CONSTRAINT FK_StaffLeaveRequests_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId)
    );
    PRINT '  + Created table dbo.StaffLeaveRequests';
END
ELSE
    PRINT '  = Table dbo.StaffLeaveRequests already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StaffLeaveRequests_StaffId'
               AND object_id = OBJECT_ID('dbo.StaffLeaveRequests'))
    CREATE INDEX IX_StaffLeaveRequests_StaffId
        ON dbo.StaffLeaveRequests (StaffId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StaffLeaveRequests_HospitalId'
               AND object_id = OBJECT_ID('dbo.StaffLeaveRequests'))
    CREATE INDEX IX_StaffLeaveRequests_HospitalId
        ON dbo.StaffLeaveRequests (HospitalId);
GO

PRINT '----------------------------------------------------------';
PRINT ' Migration completed successfully.';
PRINT '----------------------------------------------------------';
