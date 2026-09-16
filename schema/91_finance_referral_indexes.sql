-- ============================================================
-- Migration 91 — Finance/Referral indexing gaps
-- Pure performance change, no schema/behavior change. Backfills index
-- coverage for hot WHERE-clause columns that were never indexed:
--   • ReferralCommissions.AppointmentId — queried directly by equality in
--     UpdateAppointmentCommand, CollectPaymentCommand,
--     UpdateAppointmentStatusCommand, ChangeReferrerCommand and
--     InvoiceEnrichmentService, with no supporting index at all today
--     (only AppointmentServiceId and (HospitalId, UpdatedAt) are indexed).
--   • Invoices.CreatedAt — GetInvoicesQuery's default listing sorts
--     ORDER BY CreatedAt DESC, and GetFinancialMatrixQuery range-filters on
--     it; only (HospitalId, UpdatedAt) is indexed today, which doesn't
--     help either.
--   • Invoices.Status — the Billing page's PENDING/PARTIAL/PAID tab
--     filters go through this column with no supporting index.
--   • Payments.CreatedAt — GetFinancialMatrixQuery range-filters payments
--     by CreatedAt per hospital; Payments has no custom index at all today
--     (only the auto FK indexes on InvoiceId/HospitalId).
-- ============================================================

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_ReferralCommissions_AppointmentId'
      AND object_id = OBJECT_ID(N'[dbo].[ReferralCommissions]')
)
BEGIN
    CREATE INDEX [IX_ReferralCommissions_AppointmentId]
        ON [dbo].[ReferralCommissions] ([AppointmentId]);
    PRINT 'Index IX_ReferralCommissions_AppointmentId created.';
END
ELSE
BEGIN
    PRINT 'Index IX_ReferralCommissions_AppointmentId already exists - skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Invoices_Hospital_CreatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[Invoices]')
)
BEGIN
    CREATE INDEX [IX_Invoices_Hospital_CreatedAt]
        ON [dbo].[Invoices] ([HospitalId], [CreatedAt]);
    PRINT 'Index IX_Invoices_Hospital_CreatedAt created.';
END
ELSE
BEGIN
    PRINT 'Index IX_Invoices_Hospital_CreatedAt already exists - skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Invoices_Hospital_Status'
      AND object_id = OBJECT_ID(N'[dbo].[Invoices]')
)
BEGIN
    CREATE INDEX [IX_Invoices_Hospital_Status]
        ON [dbo].[Invoices] ([HospitalId], [Status]);
    PRINT 'Index IX_Invoices_Hospital_Status created.';
END
ELSE
BEGIN
    PRINT 'Index IX_Invoices_Hospital_Status already exists - skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Payments_Hospital_CreatedAt'
      AND object_id = OBJECT_ID(N'[dbo].[Payments]')
)
BEGIN
    CREATE INDEX [IX_Payments_Hospital_CreatedAt]
        ON [dbo].[Payments] ([HospitalId], [CreatedAt]);
    PRINT 'Index IX_Payments_Hospital_CreatedAt created.';
END
ELSE
BEGIN
    PRINT 'Index IX_Payments_Hospital_CreatedAt already exists - skipped.';
END
GO

PRINT 'Migration 91 applied: Finance/Referral indexing gaps closed.';
