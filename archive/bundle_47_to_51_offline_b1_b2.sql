-- =====================================================================
--  ONE-SHOT BUNDLE: migrations 47-51
--  Phase B1 + B2 schema changes for the offline-first sync engine + OCC.
--
--  Paste into a single SSMS / Azure Data Studio window and run.
--  Every step has an IF NOT EXISTS guard so the bundle is idempotent —
--  safe to re-run even if some of these migrations have already been
--  applied individually. The PRINT statements at each step tell you
--  exactly what landed vs. what was skipped.
--
--  Scope:
--    47  Appointments.UpdatedAt + DeletedAt + IX_Appointments_Hospital_UpdatedAt
--    48  Patients.UpdatedAt + DeletedAt + IX_Patients_Hospital_UpdatedAt
--    49  DiagnosticReports.DeletedAt + UpdatedAt backfill + sync index
--    50  IdempotencyKeys table + sweep index
--    51  Appointments.RowVersion + DiagnosticReports.RowVersion
--
--  Adding a ROWVERSION column (step 51) is FAST on SQL Server: existing
--  rows get a value stamped during the ALTER, no separate UPDATE pass.
--  On a multi-million-row table the lock is typically sub-second.
-- =====================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT '=== Migration 47 : Appointments sync columns ===';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'UpdatedAt'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [UpdatedAt] DATETIME2 NULL;
    -- Backfill so the next sync pull doesn't decide every legacy row is
    -- "newer than the client" and force a full refetch.
    EXEC('UPDATE [dbo].[Appointments] SET [UpdatedAt] = [DateTime] WHERE [UpdatedAt] IS NULL;');
    ALTER TABLE [dbo].[Appointments] ALTER COLUMN [UpdatedAt] DATETIME2 NOT NULL;
    PRINT '  Column dbo.Appointments.UpdatedAt added and backfilled.';
END
ELSE PRINT '  Column dbo.Appointments.UpdatedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'DeletedAt'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [DeletedAt] DATETIME2 NULL;
    PRINT '  Column dbo.Appointments.DeletedAt added.';
END
ELSE PRINT '  Column dbo.Appointments.DeletedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Appointments_Hospital_UpdatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[Appointments]')
)
BEGIN
    CREATE INDEX [IX_Appointments_Hospital_UpdatedAt]
        ON [dbo].[Appointments] ([HospitalId], [UpdatedAt]);
    PRINT '  Index IX_Appointments_Hospital_UpdatedAt created.';
END
ELSE PRINT '  Index IX_Appointments_Hospital_UpdatedAt already exists - skipped.';
GO

PRINT '=== Migration 48 : Patients sync columns ===';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Patients]') AND name = 'UpdatedAt'
)
BEGIN
    ALTER TABLE [dbo].[Patients] ADD [UpdatedAt] DATETIME2 NULL;
    EXEC('UPDATE [dbo].[Patients] SET [UpdatedAt] = [CreatedAt] WHERE [UpdatedAt] IS NULL;');
    ALTER TABLE [dbo].[Patients] ALTER COLUMN [UpdatedAt] DATETIME2 NOT NULL;
    PRINT '  Column dbo.Patients.UpdatedAt added and backfilled.';
END
ELSE PRINT '  Column dbo.Patients.UpdatedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Patients]') AND name = 'DeletedAt'
)
BEGIN
    ALTER TABLE [dbo].[Patients] ADD [DeletedAt] DATETIME2 NULL;
    PRINT '  Column dbo.Patients.DeletedAt added.';
END
ELSE PRINT '  Column dbo.Patients.DeletedAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Patients_Hospital_UpdatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[Patients]')
)
BEGIN
    CREATE INDEX [IX_Patients_Hospital_UpdatedAt]
        ON [dbo].[Patients] ([HospitalId], [UpdatedAt]);
    PRINT '  Index IX_Patients_Hospital_UpdatedAt created.';
END
ELSE PRINT '  Index IX_Patients_Hospital_UpdatedAt already exists - skipped.';
GO

PRINT '=== Migration 49 : DiagnosticReports sync hardening ===';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[DiagnosticReports]') AND name = 'DeletedAt'
)
BEGIN
    ALTER TABLE [dbo].[DiagnosticReports] ADD [DeletedAt] DATETIME2 NULL;
    PRINT '  Column dbo.DiagnosticReports.DeletedAt added.';
END
ELSE PRINT '  Column dbo.DiagnosticReports.DeletedAt already exists - skipped.';
GO

-- Legacy DiagnosticReports.UpdatedAt rows may be NULL because the column
-- was nullable when added in migration 40. Backfill so sync delta pulls
-- include them ("NULL > x" is unknown in SQL Server and would skip them).
EXEC('UPDATE [dbo].[DiagnosticReports]
      SET [UpdatedAt] = COALESCE([FinalizedAt], [CreatedAt], SYSUTCDATETIME())
      WHERE [UpdatedAt] IS NULL;');
PRINT '  DiagnosticReports.UpdatedAt backfill applied (no-op if no NULL rows).';
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_DiagnosticReports_Hospital_UpdatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[DiagnosticReports]')
)
BEGIN
    CREATE INDEX [IX_DiagnosticReports_Hospital_UpdatedAt]
        ON [dbo].[DiagnosticReports] ([HospitalId], [UpdatedAt]);
    PRINT '  Index IX_DiagnosticReports_Hospital_UpdatedAt created.';
END
ELSE PRINT '  Index IX_DiagnosticReports_Hospital_UpdatedAt already exists - skipped.';
GO

PRINT '=== Migration 50 : Idempotency dedupe table ===';
GO

IF NOT EXISTS (
    SELECT * FROM sys.tables
    WHERE name = 'IdempotencyKeys' AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    CREATE TABLE [dbo].[IdempotencyKeys] (
        [Key]                 NVARCHAR(80)     NOT NULL,
        -- UserId NOT NULL because SQL Server forbids NULL columns in a
        -- PRIMARY KEY constraint; anonymous callers store the sentinel
        -- '00000000-...' so the schema stays clean.
        [UserId]              UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT [DF_IdempotencyKeys_UserId] DEFAULT ('00000000-0000-0000-0000-000000000000'),
        [Method]              NVARCHAR(10)     NOT NULL,
        [Path]                NVARCHAR(500)    NOT NULL,
        [ResponseStatus]      INT              NOT NULL,
        [ResponseBody]        NVARCHAR(MAX)    NULL,
        [ResponseContentType] NVARCHAR(120)    NULL,
        [CreatedAt]           DATETIME2        NOT NULL CONSTRAINT [DF_IdempotencyKeys_CreatedAt] DEFAULT SYSUTCDATETIME(),
        [ExpiresAt]           DATETIME2        NOT NULL,
        CONSTRAINT [PK_IdempotencyKeys] PRIMARY KEY CLUSTERED ([Key], [UserId])
    );
    PRINT '  Table dbo.IdempotencyKeys created.';
END
ELSE PRINT '  Table dbo.IdempotencyKeys already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_IdempotencyKeys_ExpiresAt'
      AND object_id = OBJECT_ID(N'[dbo].[IdempotencyKeys]')
)
BEGIN
    CREATE INDEX [IX_IdempotencyKeys_ExpiresAt]
        ON [dbo].[IdempotencyKeys] ([ExpiresAt]);
    PRINT '  Index IX_IdempotencyKeys_ExpiresAt created.';
END
ELSE PRINT '  Index IX_IdempotencyKeys_ExpiresAt already exists - skipped.';
GO

PRINT '=== Migration 51 : OCC RowVersion columns ===';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[DiagnosticReports]') AND name = 'RowVersion'
)
BEGIN
    ALTER TABLE [dbo].[DiagnosticReports] ADD [RowVersion] ROWVERSION NOT NULL;
    PRINT '  Column dbo.DiagnosticReports.RowVersion added.';
END
ELSE PRINT '  Column dbo.DiagnosticReports.RowVersion already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'RowVersion'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [RowVersion] ROWVERSION NOT NULL;
    PRINT '  Column dbo.Appointments.RowVersion added.';
END
ELSE PRINT '  Column dbo.Appointments.RowVersion already exists - skipped.';
GO

PRINT '=== Bundle 47-51 complete ===';
GO
