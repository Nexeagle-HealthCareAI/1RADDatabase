-- ════════════════════════════════════════════════════════════════════════════
--  78_report_signoff_part11.sql
--
--  Electronic sign-off for diagnostic reports (21 CFR Part 11). Adds the
--  Draft → Preliminary → Final → Addended state machine, an identity-bound
--  signature (signer id + name/credential snapshots + server timestamp + a
--  SHA-256 content hash), append-only amendment records, and a tamper-evident,
--  hash-chained audit trail.
--
--  Run this against your 1RadDb database. Idempotent — safe to re-run.
-- ════════════════════════════════════════════════════════════════════════════

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ── 1. Sign-off columns on DiagnosticReports ────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='DiagnosticReports' AND COLUMN_NAME='Status')
BEGIN
    ALTER TABLE dbo.DiagnosticReports
        ADD [Status] NVARCHAR(20) NOT NULL CONSTRAINT [DF_DiagnosticReports_Status] DEFAULT ('Draft');
    PRINT '  + Added dbo.DiagnosticReports.Status (default Draft)';
END
ELSE PRINT '  = dbo.DiagnosticReports.Status already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='DiagnosticReports' AND COLUMN_NAME='SignedByUserId')
BEGIN
    ALTER TABLE dbo.DiagnosticReports ADD [SignedByUserId] UNIQUEIDENTIFIER NULL;
    PRINT '  + Added dbo.DiagnosticReports.SignedByUserId';
END
ELSE PRINT '  = dbo.DiagnosticReports.SignedByUserId already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='DiagnosticReports' AND COLUMN_NAME='SignerName')
BEGIN
    ALTER TABLE dbo.DiagnosticReports ADD [SignerName] NVARCHAR(200) NULL;
    PRINT '  + Added dbo.DiagnosticReports.SignerName';
END
ELSE PRINT '  = dbo.DiagnosticReports.SignerName already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='DiagnosticReports' AND COLUMN_NAME='SignerCredentials')
BEGIN
    ALTER TABLE dbo.DiagnosticReports ADD [SignerCredentials] NVARCHAR(200) NULL;
    PRINT '  + Added dbo.DiagnosticReports.SignerCredentials';
END
ELSE PRINT '  = dbo.DiagnosticReports.SignerCredentials already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='DiagnosticReports' AND COLUMN_NAME='SignedAt')
BEGIN
    ALTER TABLE dbo.DiagnosticReports ADD [SignedAt] DATETIME2 NULL;
    PRINT '  + Added dbo.DiagnosticReports.SignedAt';
END
ELSE PRINT '  = dbo.DiagnosticReports.SignedAt already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='DiagnosticReports' AND COLUMN_NAME='SignedContentHash')
BEGIN
    ALTER TABLE dbo.DiagnosticReports ADD [SignedContentHash] NVARCHAR(64) NULL;
    PRINT '  + Added dbo.DiagnosticReports.SignedContentHash';
END
ELSE PRINT '  = dbo.DiagnosticReports.SignedContentHash already exists.';
GO

-- ── 2. Backfill: existing finalised reports become Status = 'Final' ──────────
-- IsFinalized is the legacy shim; any row already finalised maps to the new
-- Final state. (Runs only where Status is still the default Draft.)
UPDATE dbo.DiagnosticReports
    SET [Status] = 'Final'
    WHERE IsFinalized = 1 AND ([Status] IS NULL OR [Status] = 'Draft');
PRINT '  ~ Backfilled Status=Final for previously finalised reports.';
GO

-- ── 3. ReportAddenda — append-only amendment records ─────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ReportAddenda' AND schema_id=SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[ReportAddenda] (
        [Id]                UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ReportAddenda_Id] DEFAULT NEWID(),
        [ReportId]          UNIQUEIDENTIFIER NOT NULL,
        [HospitalId]        UNIQUEIDENTIFIER NOT NULL,
        [AuthorUserId]      UNIQUEIDENTIFIER NULL,
        [AuthorName]        NVARCHAR(200)    NOT NULL CONSTRAINT [DF_ReportAddenda_AuthorName] DEFAULT (''),
        [AuthorCredentials] NVARCHAR(200)    NULL,
        [Text]              NVARCHAR(MAX)    NOT NULL CONSTRAINT [DF_ReportAddenda_Text] DEFAULT (''),
        [ContentHash]       NVARCHAR(64)     NULL,
        [SignedAt]          DATETIME2        NOT NULL CONSTRAINT [DF_ReportAddenda_SignedAt] DEFAULT (SYSUTCDATETIME()),
        [SortOrder]         INT              NOT NULL CONSTRAINT [DF_ReportAddenda_SortOrder] DEFAULT (0),
        [CreatedAt]         DATETIME2        NULL,
        CONSTRAINT [PK_ReportAddenda] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_ReportAddenda_DiagnosticReports_ReportId]
            FOREIGN KEY ([ReportId]) REFERENCES [dbo].[DiagnosticReports] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_ReportAddenda_Report_Sort] ON [dbo].[ReportAddenda] ([ReportId], [SortOrder]);
    PRINT 'Table dbo.ReportAddenda created.';
END
ELSE PRINT 'Table dbo.ReportAddenda already exists - skipped.';
GO

-- ── 4. ReportAuditEvents — append-only, hash-chained audit trail ─────────────
-- No FK to DiagnosticReports on purpose: the audit trail must survive even if a
-- report row is ever hard-deleted (tamper evidence).
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ReportAuditEvents' AND schema_id=SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[ReportAuditEvents] (
        [Id]            UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ReportAuditEvents_Id] DEFAULT NEWID(),
        [ReportId]      UNIQUEIDENTIFIER NOT NULL,
        [HospitalId]    UNIQUEIDENTIFIER NOT NULL,
        [EventType]     NVARCHAR(40)     NOT NULL,   -- SignedPreliminary | SignedFinal | AddendumAdded
        [ActorUserId]   UNIQUEIDENTIFIER NULL,
        [ActorName]     NVARCHAR(200)    NOT NULL CONSTRAINT [DF_ReportAuditEvents_ActorName] DEFAULT (''),
        [Timestamp]     DATETIME2        NOT NULL CONSTRAINT [DF_ReportAuditEvents_Timestamp] DEFAULT (SYSUTCDATETIME()),
        [ContentHash]   NVARCHAR(64)     NULL,
        [PreviousHash]  NVARCHAR(64)     NULL,
        [Details]       NVARCHAR(MAX)    NULL,
        CONSTRAINT [PK_ReportAuditEvents] PRIMARY KEY CLUSTERED ([Id])
    );
    CREATE INDEX [IX_ReportAuditEvents_Report_Time] ON [dbo].[ReportAuditEvents] ([ReportId], [Timestamp]);
    PRINT 'Table dbo.ReportAuditEvents created.';
END
ELSE PRINT 'Table dbo.ReportAuditEvents already exists - skipped.';
GO
