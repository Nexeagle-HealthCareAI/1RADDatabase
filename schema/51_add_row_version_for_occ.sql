-- Migration: 51_add_row_version_for_occ.sql
-- Description: Phase B2 Track 3 — optimistic concurrency control.
--              Adds SQL Server ROWVERSION columns to DiagnosticReports
--              and Appointments so save commands can detect "the row
--              changed since I last read it" and the API can return
--              409 Conflict instead of silently overwriting.
--
--              The frontend pairs this with an "Undo" toast: on 409 the
--              user's edits are replaced with the server's newer version
--              and an Undo button re-sends their content for 30 seconds.
--
-- ROWVERSION semantics: server-maintained 8-byte counter, auto-incremented
-- on every UPDATE. EF Core treats it as a concurrency token when configured
-- with .IsRowVersion(). Adding it is non-breaking: existing rows get a
-- value automatically; old clients that don't send a value will skip the
-- concurrency check (EF only enforces on tracked entities that supplied
-- one).

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[DiagnosticReports]') AND name = 'RowVersion'
)
BEGIN
    ALTER TABLE [dbo].[DiagnosticReports] ADD [RowVersion] ROWVERSION NOT NULL;
    PRINT 'Column dbo.DiagnosticReports.RowVersion added.';
END
ELSE PRINT 'Column dbo.DiagnosticReports.RowVersion already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'RowVersion'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [RowVersion] ROWVERSION NOT NULL;
    PRINT 'Column dbo.Appointments.RowVersion added.';
END
ELSE PRINT 'Column dbo.Appointments.RowVersion already exists - skipped.';
GO
