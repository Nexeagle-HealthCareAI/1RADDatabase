-- ============================================================
-- Migration 95 - ReferralBookingRequests (doctors book from their portal link)
--
-- A referring doctor's portal (/r/{id}) can now ask the centre to book a patient. It
-- lands here, NOT as a real Appointment - booking one needs a Lead Specialist (the
-- centre's own supervising physician), which an outside doctor has no way to pick.
-- Staff review the request and either book it for real through the normal New
-- Appointment flow (linking back via ResultingAppointmentId) or decline it.
--
-- No foreign keys to Referrers/Appointments on purpose: a referrer merge/delete or an
-- appointment edit must never be blocked by, or cascade into, a request row.
-- ============================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ReferralBookingRequests' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[ReferralBookingRequests] (
        [Id]                     UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ReferralBookingRequests_Id] DEFAULT (NEWID()),
        [HospitalId]             UNIQUEIDENTIFIER NOT NULL,
        [ReferrerId]             UNIQUEIDENTIFIER NOT NULL,
        [PatientName]            NVARCHAR(255)    NOT NULL,
        [Mobile]                 NVARCHAR(20)     NULL,
        [Age]                    NVARCHAR(20)     NULL,
        [Gender]                 NVARCHAR(20)     NULL,
        [Modality]               NVARCHAR(50)     NULL,
        [ServiceName]            NVARCHAR(255)    NULL,
        [PreferredDate]          DATETIME2        NULL,
        [Notes]                  NVARCHAR(1000)   NULL,
        [Status]                 NVARCHAR(20)     NOT NULL CONSTRAINT [DF_ReferralBookingRequests_Status] DEFAULT (N'PENDING'),
        [DeclineReason]          NVARCHAR(500)    NULL,
        [DecidedByUserId]        UNIQUEIDENTIFIER NULL,
        [DecidedAt]              DATETIME2        NULL,
        [ResultingAppointmentId] UNIQUEIDENTIFIER NULL,
        [CreatedAt]              DATETIME2        NOT NULL CONSTRAINT [DF_ReferralBookingRequests_CreatedAt] DEFAULT (SYSUTCDATETIME()),
        [UpdatedAt]              DATETIME2        NOT NULL CONSTRAINT [DF_ReferralBookingRequests_UpdatedAt] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_ReferralBookingRequests] PRIMARY KEY CLUSTERED ([Id])
    );
    PRINT 'Table ReferralBookingRequests created.';
END
ELSE PRINT 'Table ReferralBookingRequests already exists - skipped.';
GO

-- The front desk's queue: pending (and recently decided) requests for their centre.
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_ReferralBookingRequests_Hospital_Status_Created'
      AND object_id = OBJECT_ID(N'[dbo].[ReferralBookingRequests]')
)
BEGIN
    CREATE INDEX [IX_ReferralBookingRequests_Hospital_Status_Created]
        ON [dbo].[ReferralBookingRequests] ([HospitalId], [Status], [CreatedAt]);
    PRINT 'Index IX_ReferralBookingRequests_Hospital_Status_Created created.';
END
ELSE PRINT 'Index IX_ReferralBookingRequests_Hospital_Status_Created already exists - skipped.';
GO

-- The doctor's own portal: "my requests", newest first.
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_ReferralBookingRequests_Referrer_Created'
      AND object_id = OBJECT_ID(N'[dbo].[ReferralBookingRequests]')
)
BEGIN
    CREATE INDEX [IX_ReferralBookingRequests_Referrer_Created]
        ON [dbo].[ReferralBookingRequests] ([ReferrerId], [CreatedAt]);
    PRINT 'Index IX_ReferralBookingRequests_Referrer_Created created.';
END
ELSE PRINT 'Index IX_ReferralBookingRequests_Referrer_Created already exists - skipped.';
GO
