-- ════════════════════════════════════════════════════════════════════════════
--  80_per_service_free.sql
--
--  Per-service free billing. Until now "Mark Free" was a WHOLE-invoice flag
--  (dbo.Invoices.IsFree), so a visit was all-free or all-paid. These columns let
--  a single service line on a multi-service visit be free while the others are
--  charged. The line's gross is still recorded; it's just excluded from the
--  payable total and its referral cut is forfeited.
--
--    • dbo.AppointmentServices.IsFree — source of truth for the service line
--    • dbo.InvoiceItems.IsFree        — the billing line (excluded from payable)
--
--  Invoices.IsFree stays as an "every line is free" rollup for existing reports.
--  Run against your 1RadDb database. Idempotent — safe to re-run.
-- ════════════════════════════════════════════════════════════════════════════

SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='AppointmentServices' AND COLUMN_NAME='IsFree')
BEGIN
    ALTER TABLE dbo.AppointmentServices
        ADD [IsFree] BIT NOT NULL CONSTRAINT [DF_AppointmentServices_IsFree] DEFAULT (0);
    PRINT '  + Added dbo.AppointmentServices.IsFree';
END
ELSE PRINT '  = dbo.AppointmentServices.IsFree already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='InvoiceItems' AND COLUMN_NAME='IsFree')
BEGIN
    ALTER TABLE dbo.InvoiceItems
        ADD [IsFree] BIT NOT NULL CONSTRAINT [DF_InvoiceItems_IsFree] DEFAULT (0);
    PRINT '  + Added dbo.InvoiceItems.IsFree';
END
ELSE PRINT '  = dbo.InvoiceItems.IsFree already exists.';
GO
