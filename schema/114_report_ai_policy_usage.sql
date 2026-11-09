-- ============================================================
-- 114 REPORT AI: CENTRE RULES + USAGE LOG
-- Mirrors CentreAiPolicy / ReportAiUsageLog (ApplicationDbContext).
--
--  dbo.CentreAiPolicies   one row per centre: report AI on/off, whether
--                         cloud (browser) dictation is allowed, monthly
--                         request allowance (NULL = server default 6,000).
--  dbo.ReportAiUsageLogs  one row per report-AI request: user, feature,
--                         model, real token counts, how many identifiers
--                         were masked, outcome. Never the report text.
--
-- Safe to run more than once. Rollback: rollback/114_rollback_report_ai_policy_usage.sql
-- ============================================================
SET NOCOUNT ON;

IF OBJECT_ID('dbo.CentreAiPolicies', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CentreAiPolicies
    (
        HospitalId          UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_CentreAiPolicies PRIMARY KEY,
        ReportAiEnabled     BIT NOT NULL CONSTRAINT DF_CentreAiPolicies_Enabled DEFAULT 1,
        AllowCloudDictation BIT NOT NULL CONSTRAINT DF_CentreAiPolicies_CloudDictation DEFAULT 0,
        MonthlyCallLimit    INT NULL,
        UpdatedAt           DATETIME2 NOT NULL CONSTRAINT DF_CentreAiPolicies_UpdatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedByUserId     UNIQUEIDENTIFIER NULL,
        CONSTRAINT CK_CentreAiPolicies_Limit CHECK (MonthlyCallLimit IS NULL OR MonthlyCallLimit BETWEEN 0 AND 1000000)
    );
    PRINT 'Created dbo.CentreAiPolicies';
END
ELSE PRINT 'dbo.CentreAiPolicies already exists';

IF OBJECT_ID('dbo.ReportAiUsageLogs', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReportAiUsageLogs
    (
        ReportAiUsageLogId       UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_ReportAiUsageLogs PRIMARY KEY
            CONSTRAINT DF_ReportAiUsageLogs_Id DEFAULT NEWID(),
        HospitalId               UNIQUEIDENTIFIER NOT NULL,
        UserId                   UNIQUEIDENTIFIER NULL,
        Feature                  NVARCHAR(40) NOT NULL,
        Model                    NVARCHAR(60) NULL,
        InputTokens              INT NOT NULL CONSTRAINT DF_ReportAiUsageLogs_In DEFAULT 0,
        OutputTokens             INT NOT NULL CONSTRAINT DF_ReportAiUsageLogs_Out DEFAULT 0,
        CacheReadInputTokens     INT NOT NULL CONSTRAINT DF_ReportAiUsageLogs_CacheRead DEFAULT 0,
        CacheCreationInputTokens INT NOT NULL CONSTRAINT DF_ReportAiUsageLogs_CacheWrite DEFAULT 0,
        MaskedCount              INT NOT NULL CONSTRAINT DF_ReportAiUsageLogs_Masked DEFAULT 0,
        Outcome                  NVARCHAR(12) NOT NULL CONSTRAINT DF_ReportAiUsageLogs_Outcome DEFAULT 'ok',
        CreatedAt                DATETIME2 NOT NULL CONSTRAINT DF_ReportAiUsageLogs_CreatedAt DEFAULT SYSUTCDATETIME()
    );
    PRINT 'Created dbo.ReportAiUsageLogs';
END
ELSE PRINT 'dbo.ReportAiUsageLogs already exists';

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ReportAiUsageLogs_HospitalId_CreatedAt' AND object_id = OBJECT_ID('dbo.ReportAiUsageLogs'))
BEGIN
    CREATE INDEX IX_ReportAiUsageLogs_HospitalId_CreatedAt ON dbo.ReportAiUsageLogs (HospitalId, CreatedAt) INCLUDE (Outcome);
    PRINT 'Created IX_ReportAiUsageLogs_HospitalId_CreatedAt';
END
