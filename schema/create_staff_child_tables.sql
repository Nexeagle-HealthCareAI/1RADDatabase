/* =========================================================
   Migration: Create Staff child tables
   
   Creates StaffMemberRoles, StaffDocuments, SalaryRevisions,
   SalaryDisbursements, and HospitalLeavePolicy if they do not
   already exist. Safe to run multiple times (idempotent).
   ========================================================= */

/* ---------------------------------------------------------
   StaffMemberRoles
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.StaffMemberRoles', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.StaffMemberRoles
    (
        Id       INT NOT NULL IDENTITY(1,1)
            CONSTRAINT PK_StaffMemberRoles PRIMARY KEY,

        StaffId    UNIQUEIDENTIFIER NOT NULL,
        HospitalId UNIQUEIDENTIFIER NOT NULL,
        RoleName   NVARCHAR(100) NOT NULL,

        CONSTRAINT FK_StaffMemberRoles_Staff
            FOREIGN KEY (StaffId)
            REFERENCES dbo.StaffMembers(StaffId)
            ON DELETE CASCADE,

        CONSTRAINT FK_StaffMemberRoles_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId)
    );

    CREATE INDEX IX_StaffMemberRoles_StaffId
        ON dbo.StaffMemberRoles (StaffId);

    PRINT 'Created table dbo.StaffMemberRoles';
END
ELSE
    PRINT 'Table dbo.StaffMemberRoles already exists — skipped.';
GO

/* ---------------------------------------------------------
   StaffDocuments
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.StaffDocuments', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.StaffDocuments
    (
        DocumentId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_StaffDocuments PRIMARY KEY
            CONSTRAINT DF_StaffDocuments_DocumentId DEFAULT NEWID(),

        StaffId    UNIQUEIDENTIFIER NOT NULL,
        HospitalId UNIQUEIDENTIFIER NOT NULL,

        Category NVARCHAR(100) NOT NULL
            CONSTRAINT DF_StaffDocuments_Category DEFAULT 'Other',

        FileName        NVARCHAR(500) NOT NULL,
        ContentType     NVARCHAR(100) NULL,
        FileSizeBytes   INT NULL,
        BlobUrl         NVARCHAR(2000) NULL,

        VerificationStatus NVARCHAR(50) NOT NULL
            CONSTRAINT DF_StaffDocuments_VerificationStatus DEFAULT 'Pending',

        Notes NVARCHAR(1000) NULL,

        UploadedAt       DATETIME2 NOT NULL
            CONSTRAINT DF_StaffDocuments_UploadedAt DEFAULT GETUTCDATE(),
        UploadedByUserId UNIQUEIDENTIFIER NULL,

        CONSTRAINT FK_StaffDocuments_StaffMembers
            FOREIGN KEY (StaffId)
            REFERENCES dbo.StaffMembers(StaffId)
            ON DELETE CASCADE,

        CONSTRAINT FK_StaffDocuments_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId),

        CONSTRAINT FK_StaffDocuments_UploadedBy
            FOREIGN KEY (UploadedByUserId)
            REFERENCES dbo.Users(UserId)
    );

    CREATE INDEX IX_StaffDocuments_StaffId
        ON dbo.StaffDocuments (StaffId);

    PRINT 'Created table dbo.StaffDocuments';
END
ELSE
    PRINT 'Table dbo.StaffDocuments already exists — skipped.';
GO

/* ---------------------------------------------------------
   SalaryRevisions
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.SalaryRevisions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SalaryRevisions
    (
        RevisionId    UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_SalaryRevisions PRIMARY KEY
            CONSTRAINT DF_SalaryRevisions_RevisionId DEFAULT NEWID(),

        StaffId    UNIQUEIDENTIFIER NOT NULL,
        HospitalId UNIQUEIDENTIFIER NOT NULL,

        EffectiveFrom DATE NOT NULL,
        Note          NVARCHAR(500) NULL,

        BasicPay        DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_BasicPay    DEFAULT 0,
        Hra             DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_Hra         DEFAULT 0,
        Travel          DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_Travel      DEFAULT 0,
        OtherAllowances DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_OtherAllow  DEFAULT 0,
        PfDeduction     DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_PfDed       DEFAULT 0,
        Tds             DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_Tds         DEFAULT 0,
        OtherDeductions DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryRevisions_OtherDed    DEFAULT 0,

        CreatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_SalaryRevisions_CreatedAt DEFAULT GETUTCDATE(),

        CONSTRAINT FK_SalaryRevisions_Staff
            FOREIGN KEY (StaffId)
            REFERENCES dbo.StaffMembers(StaffId)
            ON DELETE CASCADE,

        CONSTRAINT FK_SalaryRevisions_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId)
    );

    CREATE INDEX IX_SalaryRevisions_StaffId_EffectiveFrom
        ON dbo.SalaryRevisions (StaffId, EffectiveFrom);

    PRINT 'Created table dbo.SalaryRevisions';
END
ELSE
    PRINT 'Table dbo.SalaryRevisions already exists — skipped.';
GO

/* ---------------------------------------------------------
   SalaryDisbursements
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.SalaryDisbursements', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SalaryDisbursements
    (
        DisbursementId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_SalaryDisbursements PRIMARY KEY
            CONSTRAINT DF_SalaryDisbursements_Id DEFAULT NEWID(),

        StaffId    UNIQUEIDENTIFIER NOT NULL,
        HospitalId UNIQUEIDENTIFIER NOT NULL,
        RevisionId UNIQUEIDENTIFIER NULL,

        Month NVARCHAR(7) NOT NULL,  -- 'YYYY-MM'

        GrossPay       DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisb_GrossPay  DEFAULT 0,
        NetPay         DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisb_NetPay    DEFAULT 0,
        LwpDays        DECIMAL(5,2)  NOT NULL CONSTRAINT DF_SalaryDisb_LwpDays   DEFAULT 0,
        LwpDeduction   DECIMAL(12,2) NOT NULL CONSTRAINT DF_SalaryDisb_LwpDed    DEFAULT 0,

        [Status] NVARCHAR(50) NOT NULL
            CONSTRAINT DF_SalaryDisbursements_Status DEFAULT 'Draft',

        Notes      NVARCHAR(500) NULL,
        DisbursedAt DATETIME2 NULL,
        CreatedAt   DATETIME2 NOT NULL
            CONSTRAINT DF_SalaryDisbursements_CreatedAt DEFAULT GETUTCDATE(),

        CONSTRAINT FK_SalaryDisb_Staff
            FOREIGN KEY (StaffId)
            REFERENCES dbo.StaffMembers(StaffId)
            ON DELETE CASCADE,

        CONSTRAINT FK_SalaryDisb_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId),

        CONSTRAINT FK_SalaryDisb_Revision
            FOREIGN KEY (RevisionId)
            REFERENCES dbo.SalaryRevisions(RevisionId)
            ON DELETE NO ACTION
    );

    CREATE INDEX IX_SalaryDisbursements_StaffId_Month
        ON dbo.SalaryDisbursements (StaffId, Month);

    PRINT 'Created table dbo.SalaryDisbursements';
END
ELSE
    PRINT 'Table dbo.SalaryDisbursements already exists — skipped.';
GO

/* ---------------------------------------------------------
   HospitalLeavePolicy
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.HospitalLeavePolicy', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.HospitalLeavePolicy
    (
        PolicyId   UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_HospitalLeavePolicy PRIMARY KEY
            CONSTRAINT DF_HospitalLeavePolicy_PolicyId DEFAULT NEWID(),

        HospitalId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT UQ_HospitalLeavePolicy_Hospital UNIQUE,

        LeaveTypesJson NVARCHAR(MAX) NOT NULL
            CONSTRAINT DF_HospitalLeavePolicy_Json DEFAULT '[]',

        UpdatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_HospitalLeavePolicy_UpdatedAt DEFAULT GETUTCDATE(),

        CONSTRAINT FK_HospitalLeavePolicy_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId)
    );

    PRINT 'Created table dbo.HospitalLeavePolicy';
END
ELSE
    PRINT 'Table dbo.HospitalLeavePolicy already exists — skipped.';
GO
