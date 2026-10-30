-- ============================================================
-- Migration 96 - Columns the API entities use but no earlier script created
--
-- Found by the Oct 2026 gap analysis (P0-3, P0-4). These columns exist only in the
-- stale EF migration 20260718112707, so any database built from these scripts throws
-- "Invalid column name" on:
--   * dbo.StaffLeaveRequests.SourceDisbursementId  -> every Leave read/write and every
--     salary disbursement with leave encashment (500)
--   * dbo.RadAiQuestionLogs token columns          -> every RadAI question log insert
--     (swallowed by a catch, so usage/retrain data is silently empty)
--
-- Fully guarded: safe on a database where someone already added the columns by hand.
-- ============================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- 1. StaffLeaveRequests.SourceDisbursementId (nullable, no FK on purpose: the
--    disbursement cleanup deletes the leave row itself; see DeleteSalaryDisbursement)
IF COL_LENGTH('dbo.StaffLeaveRequests', 'SourceDisbursementId') IS NULL
BEGIN
    ALTER TABLE [dbo].[StaffLeaveRequests] ADD [SourceDisbursementId] UNIQUEIDENTIFIER NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_StaffLeaveRequests_SourceDisbursementId'
                 AND object_id = OBJECT_ID('dbo.StaffLeaveRequests'))
BEGIN
    CREATE INDEX [IX_StaffLeaveRequests_SourceDisbursementId]
        ON [dbo].[StaffLeaveRequests] ([SourceDisbursementId]);
END
GO

-- 2. RadAiQuestionLogs token-usage columns (entity RadAiQuestionLog)
IF COL_LENGTH('dbo.RadAiQuestionLogs', 'Model') IS NULL
    ALTER TABLE [dbo].[RadAiQuestionLogs] ADD [Model] NVARCHAR(20) NULL;
GO
IF COL_LENGTH('dbo.RadAiQuestionLogs', 'InputTokens') IS NULL
    ALTER TABLE [dbo].[RadAiQuestionLogs] ADD [InputTokens] INT NOT NULL
        CONSTRAINT [DF_RadAiQuestionLogs_InputTokens] DEFAULT (0);
GO
IF COL_LENGTH('dbo.RadAiQuestionLogs', 'OutputTokens') IS NULL
    ALTER TABLE [dbo].[RadAiQuestionLogs] ADD [OutputTokens] INT NOT NULL
        CONSTRAINT [DF_RadAiQuestionLogs_OutputTokens] DEFAULT (0);
GO
IF COL_LENGTH('dbo.RadAiQuestionLogs', 'CacheReadInputTokens') IS NULL
    ALTER TABLE [dbo].[RadAiQuestionLogs] ADD [CacheReadInputTokens] INT NOT NULL
        CONSTRAINT [DF_RadAiQuestionLogs_CacheReadInputTokens] DEFAULT (0);
GO
IF COL_LENGTH('dbo.RadAiQuestionLogs', 'CacheHit') IS NULL
    ALTER TABLE [dbo].[RadAiQuestionLogs] ADD [CacheHit] BIT NOT NULL
        CONSTRAINT [DF_RadAiQuestionLogs_CacheHit] DEFAULT (0);
GO
IF COL_LENGTH('dbo.RadAiQuestionLogs', 'SavedInputTokens') IS NULL
    ALTER TABLE [dbo].[RadAiQuestionLogs] ADD [SavedInputTokens] INT NOT NULL
        CONSTRAINT [DF_RadAiQuestionLogs_SavedInputTokens] DEFAULT (0);
GO
IF COL_LENGTH('dbo.RadAiQuestionLogs', 'SavedOutputTokens') IS NULL
    ALTER TABLE [dbo].[RadAiQuestionLogs] ADD [SavedOutputTokens] INT NOT NULL
        CONSTRAINT [DF_RadAiQuestionLogs_SavedOutputTokens] DEFAULT (0);
GO
