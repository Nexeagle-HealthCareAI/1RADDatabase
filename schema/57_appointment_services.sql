-- Migration: 57_appointment_services.sql
-- Description: Multi-service visits (step 1 of 8).
--
-- Introduces the AppointmentServices child table — one row per service line
-- on an Appointment (X-ray, CT, USG can now coexist on a single visit) — and
-- nullable AppointmentServiceId FK columns on the four downstream tables
-- that need to attach to a specific service:
--
--   • DiagnosticReports    (one report per service)
--   • StudyAssets          (DICOM acquisitions route to the right service)
--   • ReferralCommissions  (per-service referral cut + modality breakdown)
--   • InvoiceItems         (line item belongs to the service it was billed for)
--
-- Backfill rule: every existing Appointment with a non-null Service gets
-- exactly one AppointmentService row that mirrors the parent's scalars
-- (Service/Modality/Status/timestamps). Every existing report / study /
-- commission / invoice item attached to that appointment is stamped with
-- that one service's Id, so the legacy 1:1 relationship survives the
-- migration as a "single-service" multi-service appointment.
--
-- Backwards compatibility:
--   The parent Appointment's Service + Modality scalar columns stay in
--   place for two more releases — the offline PWA cache still reads them.
--   They become canonical mirrors of the "primary" (first-created)
--   AppointmentService row. Sunset migration is queued for later.
--
-- Safe to re-run: every step is guarded with IF NOT EXISTS / WHERE NOT EXISTS.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-------------------------------------------------------------------------------
-- Step 1: AppointmentServices table
-------------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[AppointmentServices]') AND type = N'U'
)
BEGIN
    CREATE TABLE [dbo].[AppointmentServices] (
        [Id]                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT [PK_AppointmentServices] PRIMARY KEY,
        [AppointmentId]       UNIQUEIDENTIFIER NOT NULL,
        [ServiceChargeId]     UNIQUEIDENTIFIER NULL,
        [ServiceName]         NVARCHAR(255)    NOT NULL,
        [Modality]            NVARCHAR(50)     NOT NULL,
        [Amount]              DECIMAL(18, 2)   NOT NULL CONSTRAINT [DF_AppointmentServices_Amount] DEFAULT (0),
        [ReferralCutValue]    DECIMAL(18, 2)   NOT NULL CONSTRAINT [DF_AppointmentServices_RefCut] DEFAULT (0),
        [Status]              NVARCHAR(30)     NOT NULL CONSTRAINT [DF_AppointmentServices_Status] DEFAULT ('NOT_STARTED'),
        [ScanStartedAt]       DATETIME2        NULL,
        [ScanCompletedAt]     DATETIME2        NULL,
        [DeliveredAt]         DATETIME2        NULL,
        [TechnicianId]        UNIQUEIDENTIFIER NULL,
        [TechnicianComments]  NVARCHAR(1000)   NULL,
        [UpdatedAt]           DATETIME2        NOT NULL CONSTRAINT [DF_AppointmentServices_UpdatedAt] DEFAULT (SYSUTCDATETIME()),
        [DeletedAt]           DATETIME2        NULL,
        [RowVersion]          ROWVERSION       NOT NULL,
        [HospitalId]          UNIQUEIDENTIFIER NOT NULL,

        CONSTRAINT [FK_AppointmentServices_Appointments]
            FOREIGN KEY ([AppointmentId]) REFERENCES [dbo].[Appointments]([AppointmentId]) ON DELETE CASCADE,
        CONSTRAINT [FK_AppointmentServices_ServiceCharges]
            FOREIGN KEY ([ServiceChargeId]) REFERENCES [dbo].[ServiceCharges]([Id]) ON DELETE SET NULL,
        CONSTRAINT [FK_AppointmentServices_Hospitals]
            FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals]([HospitalId])
    );

    CREATE INDEX [IX_AppointmentServices_AppointmentId]
        ON [dbo].[AppointmentServices]([AppointmentId]);

    -- Delta-pull probe — same shape as Appointments / Invoices /
    -- ReferralCommissions so the SyncEngine's ?updatedAfter= queries
    -- land on a covering index per hospital tenant.
    CREATE INDEX [IX_AppointmentServices_Hospital_UpdatedAt]
        ON [dbo].[AppointmentServices]([HospitalId], [UpdatedAt]);

    PRINT 'Created table dbo.AppointmentServices.';
END
ELSE
BEGIN
    PRINT 'Table dbo.AppointmentServices already exists. Skipping creation.';
END
GO

-------------------------------------------------------------------------------
-- Step 2: nullable AppointmentServiceId FK columns on the four child tables
-------------------------------------------------------------------------------

-- DiagnosticReports
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[DiagnosticReports]') AND name = N'AppointmentServiceId'
)
BEGIN
    ALTER TABLE [dbo].[DiagnosticReports]
        ADD [AppointmentServiceId] UNIQUEIDENTIFIER NULL;
END
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_DiagnosticReports_AppointmentServices'
)
BEGIN
    ALTER TABLE [dbo].[DiagnosticReports]
        ADD CONSTRAINT [FK_DiagnosticReports_AppointmentServices]
            FOREIGN KEY ([AppointmentServiceId]) REFERENCES [dbo].[AppointmentServices]([Id]) ON DELETE SET NULL;
END
GO

-- StudyAssets
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[StudyAssets]') AND name = N'AppointmentServiceId'
)
BEGIN
    ALTER TABLE [dbo].[StudyAssets]
        ADD [AppointmentServiceId] UNIQUEIDENTIFIER NULL;
END
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StudyAssets_AppointmentServices'
)
BEGIN
    ALTER TABLE [dbo].[StudyAssets]
        ADD CONSTRAINT [FK_StudyAssets_AppointmentServices]
            FOREIGN KEY ([AppointmentServiceId]) REFERENCES [dbo].[AppointmentServices]([Id]) ON DELETE SET NULL;
END
GO

-- ReferralCommissions
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[ReferralCommissions]') AND name = N'AppointmentServiceId'
)
BEGIN
    ALTER TABLE [dbo].[ReferralCommissions]
        ADD [AppointmentServiceId] UNIQUEIDENTIFIER NULL;
END
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ReferralCommissions_AppointmentServices'
)
BEGIN
    ALTER TABLE [dbo].[ReferralCommissions]
        ADD CONSTRAINT [FK_ReferralCommissions_AppointmentServices]
            FOREIGN KEY ([AppointmentServiceId]) REFERENCES [dbo].[AppointmentServices]([Id]) ON DELETE SET NULL;
END
GO

-- InvoiceItems
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[InvoiceItems]') AND name = N'AppointmentServiceId'
)
BEGIN
    ALTER TABLE [dbo].[InvoiceItems]
        ADD [AppointmentServiceId] UNIQUEIDENTIFIER NULL;
END
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_InvoiceItems_AppointmentServices'
)
BEGIN
    ALTER TABLE [dbo].[InvoiceItems]
        ADD CONSTRAINT [FK_InvoiceItems_AppointmentServices]
            FOREIGN KEY ([AppointmentServiceId]) REFERENCES [dbo].[AppointmentServices]([Id]) ON DELETE SET NULL;
END
GO

-------------------------------------------------------------------------------
-- Step 3: backfill one AppointmentService per existing Appointment
-------------------------------------------------------------------------------
-- For every existing appointment that doesn't already have a child service
-- row (re-runs are no-ops), insert one row mirroring the scalar
-- Service/Modality. Status maps from Appointment.ReportProgressStatus where
-- possible — "DELIVERED" stays DELIVERED, "COMPLETED" maps to REPORTED,
-- "IN_PROGRESS" maps to SCANNED, everything else lands on NOT_STARTED.
INSERT INTO [dbo].[AppointmentServices]
    ([Id], [AppointmentId], [ServiceChargeId], [ServiceName], [Modality],
     [Amount], [ReferralCutValue],
     [Status], [ScanStartedAt], [ScanCompletedAt], [DeliveredAt],
     [TechnicianId], [TechnicianComments],
     [UpdatedAt], [HospitalId])
SELECT
    NEWID(),
    a.[AppointmentId],
    NULL,
    ISNULL(NULLIF(a.[Service],  N''), N'(unspecified)'),
    ISNULL(NULLIF(a.[Modality], N''), N'OT'),
    0,
    0,
    CASE
        WHEN a.[ReportProgressStatus] = N'DELIVERED'   THEN N'DELIVERED'
        WHEN a.[ReportProgressStatus] = N'COMPLETED'   THEN N'REPORTED'
        WHEN a.[ReportProgressStatus] = N'IN_PROGRESS' THEN N'SCANNED'
        WHEN a.[Status] = N'CANCELLED'                 THEN N'CANCELLED'
        ELSE N'NOT_STARTED'
    END,
    a.[ScanStartedAt],
    a.[ScannedAt],
    a.[DeliveredAt],
    a.[TechnicianId],
    a.[TechnicianComments],
    ISNULL(a.[UpdatedAt], SYSUTCDATETIME()),
    a.[HospitalId]
FROM [dbo].[Appointments] a
WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[AppointmentServices] s WHERE s.[AppointmentId] = a.[AppointmentId]
    );

DECLARE @backfilledServices INT = @@ROWCOUNT;
PRINT CONCAT('Backfilled ', @backfilledServices, ' AppointmentService row(s) from existing appointments.');
GO

-------------------------------------------------------------------------------
-- Step 4: stamp child rows with the AppointmentServiceId they now belong to
-------------------------------------------------------------------------------
-- Because backfill produced exactly one service row per legacy appointment,
-- the resolution is unambiguous — every existing child row that's not
-- already stamped (re-run-safe) maps to its appointment's only service row.

UPDATE r
   SET r.[AppointmentServiceId] = s.[Id]
  FROM [dbo].[DiagnosticReports] r
  JOIN [dbo].[AppointmentServices] s ON s.[AppointmentId] = r.[AppointmentId]
 WHERE r.[AppointmentServiceId] IS NULL;
DECLARE @backReports INT = @@ROWCOUNT;
PRINT CONCAT('Stamped ', @backReports, ' DiagnosticReports with AppointmentServiceId.');

UPDATE sa
   SET sa.[AppointmentServiceId] = s.[Id]
  FROM [dbo].[StudyAssets] sa
  JOIN [dbo].[AppointmentServices] s ON s.[AppointmentId] = sa.[AppointmentId]
 WHERE sa.[AppointmentServiceId] IS NULL;
DECLARE @backAssets INT = @@ROWCOUNT;
PRINT CONCAT('Stamped ', @backAssets, ' StudyAssets with AppointmentServiceId.');

UPDATE rc
   SET rc.[AppointmentServiceId] = s.[Id]
  FROM [dbo].[ReferralCommissions] rc
  JOIN [dbo].[AppointmentServices] s ON s.[AppointmentId] = rc.[AppointmentId]
 WHERE rc.[AppointmentServiceId] IS NULL
   AND rc.[AppointmentId] IS NOT NULL;
DECLARE @backCommissions INT = @@ROWCOUNT;
PRINT CONCAT('Stamped ', @backCommissions, ' ReferralCommissions with AppointmentServiceId.');

UPDATE ii
   SET ii.[AppointmentServiceId] = s.[Id]
  FROM [dbo].[InvoiceItems] ii
  JOIN [dbo].[Invoices] inv ON inv.[Id] = ii.[InvoiceId]
  JOIN [dbo].[AppointmentServices] s ON s.[AppointmentId] = inv.[AppointmentId]
 WHERE ii.[AppointmentServiceId] IS NULL
   AND inv.[AppointmentId] IS NOT NULL;
DECLARE @backItems INT = @@ROWCOUNT;
PRINT CONCAT('Stamped ', @backItems, ' InvoiceItems with AppointmentServiceId.');
GO
