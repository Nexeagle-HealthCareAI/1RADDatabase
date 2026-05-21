/* =========================================================
   31 - Staff Members (HR Records)
   
   Separates HR staff records from board user accounts.
   A staff member can exist without a board login.
   ========================================================= */

/* ---------------------------------------------------------
   1. StaffMembers — core HR record
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.StaffMembers', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.StaffMembers
    (
        StaffId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_StaffMembers PRIMARY KEY
            CONSTRAINT DF_StaffMembers_StaffId DEFAULT NEWID(),

        HospitalId UNIQUEIDENTIFIER NOT NULL,

        FullName NVARCHAR(255) NOT NULL,
        Email NVARCHAR(255) NULL,
        Mobile NVARCHAR(20) NULL,

        Designation NVARCHAR(100) NULL,
        Department  NVARCHAR(100) NULL,
        EmploymentType NVARCHAR(50) NOT NULL
            CONSTRAINT DF_StaffMembers_EmploymentType DEFAULT 'Full-Time',

        Specialization NVARCHAR(500) NULL,
        Degree         NVARCHAR(255) NULL,
        LicenseNo      NVARCHAR(100) NULL,

        JoiningDate DATE NULL,

        [Status] NVARCHAR(50) NOT NULL
            CONSTRAINT DF_StaffMembers_Status DEFAULT 'Active',

        -- Profile photo (stored in staff-documents container)
        PhotoUrl  NVARCHAR(2000) NULL,
        PhotoPath NVARCHAR(500)  NULL,

        CreatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_StaffMembers_CreatedAt DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2 NULL,

        CONSTRAINT FK_StaffMembers_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId)
    );
    PRINT 'Created table dbo.StaffMembers';
END
ELSE
    PRINT 'Table dbo.StaffMembers already exists — skipped.';
GO

/* ---------------------------------------------------------
   2. StaffMemberRoles — job category (Doctor, Technician…)
      Used for HR filtering. Separate from board roles.
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.StaffMemberRoles', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.StaffMemberRoles
    (
        Id       INT NOT NULL IDENTITY(1,1)
            CONSTRAINT PK_StaffMemberRoles PRIMARY KEY,
        StaffId  UNIQUEIDENTIFIER NOT NULL,
        RoleName NVARCHAR(50) NOT NULL,

        CONSTRAINT FK_StaffMemberRoles_StaffMembers
            FOREIGN KEY (StaffId)
            REFERENCES dbo.StaffMembers(StaffId)
            ON DELETE CASCADE,

        CONSTRAINT UQ_StaffMemberRoles
            UNIQUE (StaffId, RoleName)
    );
    PRINT 'Created table dbo.StaffMemberRoles';
END
ELSE
    PRINT 'Table dbo.StaffMemberRoles already exists — skipped.';
GO

/* ---------------------------------------------------------
   3. StaffDocuments — verification documents per staff
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
        -- Values: 'ID Proof', 'Medical License', 'Degree / Certificate',
        --         'Employment Contract', 'Background Check', 'Other'

        FileName        NVARCHAR(500) NOT NULL,
        ContentType     NVARCHAR(100) NULL,
        FileSizeBytes   INT NULL,
        BlobUrl         NVARCHAR(2000) NULL,  -- Azure Blob Storage URL
        BlobPath        NVARCHAR(500)  NULL,  -- Relative path inside the container (e.g. "hospital/staff/doc_file.pdf")
        BlobContainer   NVARCHAR(100)  NULL,  -- Container name (defaults to "staff-documents")

        VerificationStatus NVARCHAR(50) NOT NULL
            CONSTRAINT DF_StaffDocuments_VerificationStatus DEFAULT 'Pending',
        -- Values: 'Pending', 'Verified', 'Rejected'

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
    PRINT 'Created table dbo.StaffDocuments';
END
ELSE
    PRINT 'Table dbo.StaffDocuments already exists — skipped.';
GO

/* ---------------------------------------------------------
   4. Indexes for common query patterns
   --------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StaffMembers_HospitalId'
               AND object_id = OBJECT_ID('dbo.StaffMembers'))
    CREATE INDEX IX_StaffMembers_HospitalId
        ON dbo.StaffMembers (HospitalId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StaffDocuments_StaffId'
               AND object_id = OBJECT_ID('dbo.StaffDocuments'))
    CREATE INDEX IX_StaffDocuments_StaffId
        ON dbo.StaffDocuments (StaffId);
GO
