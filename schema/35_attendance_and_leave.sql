/* =========================================================
   35 – Staff Attendance & Leave Requests

   StaffAttendance  – one row per (StaffId, Date), upsertable.
   StaffLeaveRequests – one row per leave application.
   ========================================================= */

/* ---------------------------------------------------------
   1. StaffAttendance
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.StaffAttendance', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.StaffAttendance
    (
        AttendanceId   UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_StaffAttendance PRIMARY KEY
            CONSTRAINT DF_StaffAttendance_Id DEFAULT NEWID(),

        StaffId        UNIQUEIDENTIFIER NOT NULL,
        HospitalId     UNIQUEIDENTIFIER NOT NULL,

        AttendanceDate DATE NOT NULL,

        -- present | absent | halfday | late | leave
        [Status] NVARCHAR(20) NOT NULL
            CONSTRAINT DF_StaffAttendance_Status DEFAULT 'present',

        Note           NVARCHAR(500) NULL,
        MarkedByUserId UNIQUEIDENTIFIER NULL,
        MarkedAt       DATETIME2 NOT NULL
            CONSTRAINT DF_StaffAttendance_MarkedAt DEFAULT GETUTCDATE(),

        CONSTRAINT FK_StaffAttendance_Staff
            FOREIGN KEY (StaffId)
            REFERENCES dbo.StaffMembers(StaffId)
            ON DELETE CASCADE,

        CONSTRAINT FK_StaffAttendance_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId),

        -- One record per staff per calendar day
        CONSTRAINT UX_StaffAttendance_StaffDate
            UNIQUE (StaffId, AttendanceDate)
    );
    PRINT 'Created table dbo.StaffAttendance';
END
ELSE
    PRINT 'Table dbo.StaffAttendance already exists — skipped.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StaffAttendance_HospitalId_Date'
               AND object_id = OBJECT_ID('dbo.StaffAttendance'))
    CREATE INDEX IX_StaffAttendance_HospitalId_Date
        ON dbo.StaffAttendance (HospitalId, AttendanceDate);
GO

/* ---------------------------------------------------------
   2. StaffLeaveRequests
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.StaffLeaveRequests', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.StaffLeaveRequests
    (
        LeaveRequestId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_StaffLeaveRequests PRIMARY KEY
            CONSTRAINT DF_StaffLeaveRequests_Id DEFAULT NEWID(),

        StaffId    UNIQUEIDENTIFIER NOT NULL,
        HospitalId UNIQUEIDENTIFIER NOT NULL,

        LeaveType NVARCHAR(100) NOT NULL,

        FromDate DATE NOT NULL,
        ToDate   DATE NOT NULL,
        Days     INT  NOT NULL,

        Reason NVARCHAR(1000) NULL,

        -- pending | approved | rejected
        [Status] NVARCHAR(20) NOT NULL
            CONSTRAINT DF_StaffLeaveRequests_Status DEFAULT 'pending',

        AppliedOn        DATETIME2 NOT NULL
            CONSTRAINT DF_StaffLeaveRequests_AppliedOn DEFAULT GETUTCDATE(),

        ReviewedByUserId UNIQUEIDENTIFIER NULL,
        ReviewedAt       DATETIME2 NULL,

        CONSTRAINT FK_StaffLeaveRequests_Staff
            FOREIGN KEY (StaffId)
            REFERENCES dbo.StaffMembers(StaffId)
            ON DELETE CASCADE,

        CONSTRAINT FK_StaffLeaveRequests_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId)
    );
    PRINT 'Created table dbo.StaffLeaveRequests';
END
ELSE
    PRINT 'Table dbo.StaffLeaveRequests already exists — skipped.';
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
