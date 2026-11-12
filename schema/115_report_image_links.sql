-- ============================================================
-- 115 REPORT <-> IMAGE LINKS + AI DRAFTING GROUNDWORK
-- Mirrors ReportKeyImage / ReportAiDraft / ApprovedReportCase and two new
-- CentreAiPolicy switches (ApplicationDbContext).
--
--  dbo.ReportKeyImages      images the doctor marked as key (exact DICOM
--                           instance), per visit study or PACS study.
--  dbo.ReportAiDrafts       AI drafts (from key images or dictation), kept to
--                           compare with what the doctor signed.
--  dbo.ApprovedReportCases  Final reports kept DE-IDENTIFIED with their image
--                           references and AI-draft comparison — only for
--                           centres that opt in.
--  CentreAiPolicies.VisionDraftEnabled   (default 0)
--  CentreAiPolicies.CaptureApprovedCases (default 0)
--
-- Requires 114. Safe to run more than once.
-- Rollback: rollback/115_rollback_report_image_links.sql
-- ============================================================
SET NOCOUNT ON;

IF OBJECT_ID('dbo.CentreAiPolicies', 'U') IS NULL
    THROW 51150, 'Run 114_report_ai_policy_usage.sql first.', 1;

IF COL_LENGTH('dbo.CentreAiPolicies', 'VisionDraftEnabled') IS NULL
    ALTER TABLE dbo.CentreAiPolicies ADD VisionDraftEnabled BIT NOT NULL
        CONSTRAINT DF_CentreAiPolicies_VisionDraft DEFAULT 0;
IF COL_LENGTH('dbo.CentreAiPolicies', 'CaptureApprovedCases') IS NULL
    ALTER TABLE dbo.CentreAiPolicies ADD CaptureApprovedCases BIT NOT NULL
        CONSTRAINT DF_CentreAiPolicies_Capture DEFAULT 0;

IF OBJECT_ID('dbo.ReportKeyImages', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReportKeyImages
    (
        Id                   UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ReportKeyImages PRIMARY KEY
                                 CONSTRAINT DF_ReportKeyImages_Id DEFAULT NEWID(),
        HospitalId           UNIQUEIDENTIFIER NOT NULL,
        AppointmentId        UNIQUEIDENTIFIER NULL,
        AppointmentServiceId UNIQUEIDENTIFIER NULL,
        ImagingStudyId       UNIQUEIDENTIFIER NULL,
        StudyAssetId         UNIQUEIDENTIFIER NULL,
        SeriesInstanceUid    NVARCHAR(64) NULL,
        SopInstanceUid       NVARCHAR(64) NOT NULL,
        FrameIndex           INT NULL,
        SliceIndex           INT NULL,
        Note                 NVARCHAR(200) NULL,
        CreatedByUserId      UNIQUEIDENTIFIER NULL,
        CreatedAt            DATETIME2 NOT NULL CONSTRAINT DF_ReportKeyImages_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_ReportKeyImages_Owner CHECK (AppointmentId IS NOT NULL OR ImagingStudyId IS NOT NULL)
    );
    CREATE INDEX IX_ReportKeyImages_Visit ON dbo.ReportKeyImages (AppointmentId, AppointmentServiceId);
    CREATE INDEX IX_ReportKeyImages_Study ON dbo.ReportKeyImages (ImagingStudyId);
    PRINT 'Created dbo.ReportKeyImages';
END

IF OBJECT_ID('dbo.ReportAiDrafts', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReportAiDrafts
    (
        Id                   UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ReportAiDrafts PRIMARY KEY
                                 CONSTRAINT DF_ReportAiDrafts_Id DEFAULT NEWID(),
        HospitalId           UNIQUEIDENTIFIER NOT NULL,
        AppointmentId        UNIQUEIDENTIFIER NULL,
        AppointmentServiceId UNIQUEIDENTIFIER NULL,
        ImagingStudyId       UNIQUEIDENTIFIER NULL,
        Source               NVARCHAR(12) NOT NULL,
        Model                NVARCHAR(60) NULL,
        Findings             NVARCHAR(MAX) NOT NULL,
        Impression           NVARCHAR(MAX) NULL,
        KeyImageSopUids      NVARCHAR(MAX) NULL,
        Applied              BIT NOT NULL CONSTRAINT DF_ReportAiDrafts_Applied DEFAULT 0,
        CreatedByUserId      UNIQUEIDENTIFIER NULL,
        CreatedAt            DATETIME2 NOT NULL CONSTRAINT DF_ReportAiDrafts_CreatedAt DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_ReportAiDrafts_Visit ON dbo.ReportAiDrafts (AppointmentId, AppointmentServiceId);
    CREATE INDEX IX_ReportAiDrafts_Study ON dbo.ReportAiDrafts (ImagingStudyId);
    PRINT 'Created dbo.ReportAiDrafts';
END

IF OBJECT_ID('dbo.ApprovedReportCases', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ApprovedReportCases
    (
        Id                     UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ApprovedReportCases PRIMARY KEY
                                   CONSTRAINT DF_ApprovedReportCases_Id DEFAULT NEWID(),
        HospitalId             UNIQUEIDENTIFIER NOT NULL,
        DiagnosticReportId     UNIQUEIDENTIFIER NOT NULL,
        Modality               NVARCHAR(20) NULL,
        StudyName              NVARCHAR(200) NULL,
        StudyInstanceUid       NVARCHAR(64) NULL,
        KeyImagesJson          NVARCHAR(MAX) NULL,
        FindingsDeidentified   NVARCHAR(MAX) NOT NULL,
        ImpressionDeidentified NVARCHAR(MAX) NULL,
        AiDraftId              UNIQUEIDENTIFIER NULL,
        AiDraftSource          NVARCHAR(12) NULL,
        DraftSimilarity        FLOAT NULL,
        DraftEditDistance      INT NULL,
        SignedContentHash      NVARCHAR(128) NOT NULL,
        SignedAt               DATETIME2 NOT NULL,
        CreatedAt              DATETIME2 NOT NULL CONSTRAINT DF_ApprovedReportCases_CreatedAt DEFAULT SYSUTCDATETIME()
    );
    CREATE UNIQUE INDEX UX_ApprovedReportCases_Report ON dbo.ApprovedReportCases (DiagnosticReportId);
    CREATE INDEX IX_ApprovedReportCases_Modality ON dbo.ApprovedReportCases (HospitalId, Modality);
    PRINT 'Created dbo.ApprovedReportCases';
END
