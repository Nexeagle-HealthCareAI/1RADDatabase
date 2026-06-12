-- =========================================================================================
-- MIGRATION: 77_extraction_leased_queue.sql
-- DESCRIPTION: Turns the DICOM extraction pipeline into a DURABLE, MULTI-INSTANCE
--              work queue. The StudyAssets table itself is the queue: a 'Queued'
--              row is a job, claimed atomically with a LEASE so many API instances
--              (multi-centre, many concurrent users) pull DISTINCT work via READPAST
--              with no double-processing, and a crashed instance's lease expires so
--              the job is reclaimed. Adds durable retry/backoff and live progress
--              columns (read by the viewer's status poll on any instance), plus a
--              filtered index so "claim the next ready job" stays a cheap seek.
--
--              Pairs with: IApplicationDbContext.ClaimNextExtractionJobAsync /
--              RenewExtractionLeaseAsync and DicomExtractionWorker.
-- =========================================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;
GO

-- ─── StudyAssets — leased-queue + retry + live-progress columns ───────────────────────

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ExtractionLeaseOwner' AND Object_ID = Object_ID(N'dbo.StudyAssets'))
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionLeaseOwner] NVARCHAR(64) NULL;
    PRINT 'Added ExtractionLeaseOwner to StudyAssets.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ExtractionLeaseUntil' AND Object_ID = Object_ID(N'dbo.StudyAssets'))
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionLeaseUntil] DATETIME2 NULL;
    PRINT 'Added ExtractionLeaseUntil to StudyAssets.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ExtractionAttempts' AND Object_ID = Object_ID(N'dbo.StudyAssets'))
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionAttempts] INT NOT NULL CONSTRAINT [DF_StudyAssets_ExtractionAttempts] DEFAULT 0;
    PRINT 'Added ExtractionAttempts to StudyAssets.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ExtractionNextAttemptAt' AND Object_ID = Object_ID(N'dbo.StudyAssets'))
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionNextAttemptAt] DATETIME2 NULL;
    PRINT 'Added ExtractionNextAttemptAt to StudyAssets.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ExtractionPhase' AND Object_ID = Object_ID(N'dbo.StudyAssets'))
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionPhase] NVARCHAR(32) NULL;
    PRINT 'Added ExtractionPhase to StudyAssets.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ExtractionProcessedSlices' AND Object_ID = Object_ID(N'dbo.StudyAssets'))
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionProcessedSlices] INT NOT NULL CONSTRAINT [DF_StudyAssets_ExtractionProcessedSlices] DEFAULT 0;
    PRINT 'Added ExtractionProcessedSlices to StudyAssets.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ExtractionTotalSlices' AND Object_ID = Object_ID(N'dbo.StudyAssets'))
BEGIN
    ALTER TABLE [dbo].[StudyAssets] ADD [ExtractionTotalSlices] INT NOT NULL CONSTRAINT [DF_StudyAssets_ExtractionTotalSlices] DEFAULT 0;
    PRINT 'Added ExtractionTotalSlices to StudyAssets.';
END
GO

-- ─── Claim index: only LIVE jobs are indexed, so the claim query is a tiny seek ───────
-- even as millions of finished ('Extracted') rows accumulate.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_StudyAssets_ExtractionClaim' AND object_id = Object_ID(N'dbo.StudyAssets'))
BEGIN
    CREATE INDEX [IX_StudyAssets_ExtractionClaim]
        ON [dbo].[StudyAssets] ([ExtractionStatus], [ExtractionNextAttemptAt], [ExtractionLeaseUntil])
        INCLUDE ([FileType], [UploadedAt])
        WHERE [ExtractionStatus] IN ('Queued', 'Running');
    PRINT 'Created filtered index IX_StudyAssets_ExtractionClaim.';
END
GO

COMMIT TRANSACTION;
GO

PRINT '✅ Migration 77_extraction_leased_queue.sql completed.';
GO
