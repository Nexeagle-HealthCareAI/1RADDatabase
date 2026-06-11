-- ============================================================
-- RADAI QUESTION LOG MIGRATION
-- Captures one row per answered RadAI question so the "retrain"
-- loop can find the most-asked + uncovered questions to add to
-- app_knowledge.json. Mirrors the RadAiQuestionLog entity /
-- ApplicationDbContext config (table dbo.RadAiQuestionLogs).
--
-- Run this against your 1RadDb database.
-- Safe to run multiple times — every step is idempotent.
-- ============================================================

SET NOCOUNT ON;
PRINT '----------------------------------------------------------';
PRINT ' Starting RadAI question log migration';
PRINT '----------------------------------------------------------';

/* ============================================================
   1. dbo.RadAiQuestionLogs — one row per answered RadAI question
   ============================================================ */
IF OBJECT_ID('dbo.RadAiQuestionLogs', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RadAiQuestionLogs
    (
        RadAiQuestionLogId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_RadAiQuestionLogs PRIMARY KEY
            CONSTRAINT DF_RadAiQuestionLogs_Id DEFAULT NEWID(),

        HospitalId    UNIQUEIDENTIFIER NOT NULL,

        AskedByUserId UNIQUEIDENTIFIER NULL,
        SessionId     UNIQUEIDENTIFIER NULL,

        -- The typed question. NULL for voice questions (no transcript yet);
        -- WasVoice flags those rows.
        Question      NVARCHAR(2000) NULL,
        WasVoice      BIT NOT NULL
            CONSTRAINT DF_RadAiQuestionLogs_WasVoice DEFAULT 0,

        Page          NVARCHAR(200) NULL,
        ReplyLanguage NVARCHAR(8)   NULL,

        -- FALSE => the knowledge base did not cover this question
        -- (the highest-value gaps to fix in app_knowledge.json).
        Covered       BIT NOT NULL
            CONSTRAINT DF_RadAiQuestionLogs_Covered DEFAULT 1,

        -- Short, PHI-free snippet of the answer for quick review.
        AnswerSnippet NVARCHAR(500) NULL,

        CreatedAt     DATETIME2 NOT NULL
            CONSTRAINT DF_RadAiQuestionLogs_CreatedAt DEFAULT GETUTCDATE(),

        CONSTRAINT FK_RadAiQuestionLogs_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId)
    );
    PRINT '  + Created table dbo.RadAiQuestionLogs';
END
ELSE
    PRINT '  = Table dbo.RadAiQuestionLogs already exists.';
GO

/* ============================================================
   2. Indexes — scoped queries for the retrain helper
   ============================================================ */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RadAiQuestionLogs_Hospital_Created'
               AND object_id = OBJECT_ID('dbo.RadAiQuestionLogs'))
BEGIN
    CREATE INDEX IX_RadAiQuestionLogs_Hospital_Created
        ON dbo.RadAiQuestionLogs (HospitalId, CreatedAt);
    PRINT '  + Created index IX_RadAiQuestionLogs_Hospital_Created';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RadAiQuestionLogs_Hospital_Covered'
               AND object_id = OBJECT_ID('dbo.RadAiQuestionLogs'))
BEGIN
    CREATE INDEX IX_RadAiQuestionLogs_Hospital_Covered
        ON dbo.RadAiQuestionLogs (HospitalId, Covered);
    PRINT '  + Created index IX_RadAiQuestionLogs_Hospital_Covered';
END
GO

PRINT '----------------------------------------------------------';
PRINT ' Migration completed successfully.';
PRINT '----------------------------------------------------------';
