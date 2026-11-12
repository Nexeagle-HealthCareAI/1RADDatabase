-- ============================================================
-- Migration 99 - JobRuns: run each scheduled job once per slot, even with several
-- API instances (gap analysis P3-9)
--
-- Every API instance runs the same hosted jobs. A job now claims its slot first by
-- inserting (JobName, RunKey) — e.g. ('DailyFinancialReport', '2026-10-30'); the
-- unique index lets exactly one instance win, so admins get one email, not one per
-- instance.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.JobRuns', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[JobRuns] (
        [Id]        BIGINT IDENTITY(1,1) NOT NULL,
        [JobName]   NVARCHAR(100) NOT NULL,
        [RunKey]    NVARCHAR(50)  NOT NULL,
        [ClaimedBy] NVARCHAR(200) NULL,          -- machine name of the winning instance
        [ClaimedAt] DATETIME2     NOT NULL CONSTRAINT [DF_JobRuns_ClaimedAt] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_JobRuns] PRIMARY KEY CLUSTERED ([Id])
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_JobRuns_Job_RunKey' AND object_id = OBJECT_ID('dbo.JobRuns'))
    CREATE UNIQUE INDEX [UX_JobRuns_Job_RunKey] ON [dbo].[JobRuns] ([JobName], [RunKey]);
GO
