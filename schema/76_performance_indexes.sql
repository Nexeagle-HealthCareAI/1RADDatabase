-- ============================================================
-- PERFORMANCE INDEXES — appointment + billing read paths
-- Run this against your 1RadDb database.
-- Safe to run multiple times (checks index existence first).
--
-- These speed up the hottest read paths:
--   • the worklist / appointment sync delta (HospitalId + UpdatedAt)
--   • the board's date slices + ordering (HospitalId + DateTime)
--   • the Revenue Hub / invoice sync delta (HospitalId + UpdatedAt)
--   • GetInvoices' per-appointment commission lookup (AppointmentId)
-- ============================================================

-- Worklist + appointment sync delta:  WHERE HospitalId = @h AND UpdatedAt > @since
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Appointments_Hospital_UpdatedAt' AND object_id = OBJECT_ID('dbo.Appointments'))
BEGIN
    CREATE INDEX IX_Appointments_Hospital_UpdatedAt ON dbo.Appointments (HospitalId, UpdatedAt);
    PRINT 'Created IX_Appointments_Hospital_UpdatedAt.';
END
ELSE PRINT 'IX_Appointments_Hospital_UpdatedAt already exists. Skipping.';

-- Worklist date slices + ordering:  WHERE HospitalId = @h ... ORDER BY DateTime
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Appointments_Hospital_DateTime' AND object_id = OBJECT_ID('dbo.Appointments'))
BEGIN
    CREATE INDEX IX_Appointments_Hospital_DateTime ON dbo.Appointments (HospitalId, [DateTime]);
    PRINT 'Created IX_Appointments_Hospital_DateTime.';
END
ELSE PRINT 'IX_Appointments_Hospital_DateTime already exists. Skipping.';

-- Revenue Hub + invoice sync delta:  WHERE HospitalId = @h AND UpdatedAt > @since
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Invoices_Hospital_UpdatedAt' AND object_id = OBJECT_ID('dbo.Invoices'))
BEGIN
    CREATE INDEX IX_Invoices_Hospital_UpdatedAt ON dbo.Invoices (HospitalId, UpdatedAt);
    PRINT 'Created IX_Invoices_Hospital_UpdatedAt.';
END
ELSE PRINT 'IX_Invoices_Hospital_UpdatedAt already exists. Skipping.';

-- GetInvoices per-appointment commission lookup:  WHERE AppointmentId = @a
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ReferralCommissions_AppointmentId' AND object_id = OBJECT_ID('dbo.ReferralCommissions'))
BEGIN
    CREATE INDEX IX_ReferralCommissions_AppointmentId ON dbo.ReferralCommissions (AppointmentId);
    PRINT 'Created IX_ReferralCommissions_AppointmentId.';
END
ELSE PRINT 'IX_ReferralCommissions_AppointmentId already exists. Skipping.';

-- Referral commission sync delta
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ReferralCommissions_Hospital_UpdatedAt' AND object_id = OBJECT_ID('dbo.ReferralCommissions'))
BEGIN
    CREATE INDEX IX_ReferralCommissions_Hospital_UpdatedAt ON dbo.ReferralCommissions (HospitalId, UpdatedAt);
    PRINT 'Created IX_ReferralCommissions_Hospital_UpdatedAt.';
END
ELSE PRINT 'IX_ReferralCommissions_Hospital_UpdatedAt already exists. Skipping.';
