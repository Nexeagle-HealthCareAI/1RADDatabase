-- ============================================================
-- Migration 97 - AuditLogs: who changed what (gap analysis P3-8)
--
-- Report sign-off already has its own hash-chained ReportAuditEvents. Everything
-- else (patients, appointments, money, prices, staff, roles, subscriptions) had no
-- record of who changed what. The API now writes one row per changed entity in the
-- same transaction as the change (ApplicationDbContext.SaveChangesAsync → AuditTrail).
-- Passwords, hashes and tokens are never written here.
-- Append-only by convention; no FKs so audit rows outlive what they describe.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.AuditLogs', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[AuditLogs] (
        [Id]          BIGINT IDENTITY(1,1) NOT NULL,
        [HospitalId]  UNIQUEIDENTIFIER NOT NULL,
        [UserId]      UNIQUEIDENTIFIER NULL,           -- null = background job / anonymous
        [EntityType]  NVARCHAR(100)    NOT NULL,       -- e.g. Invoice
        [EntityId]    NVARCHAR(100)    NOT NULL,       -- primary key value(s)
        [Action]      NVARCHAR(20)     NOT NULL,       -- Added | Modified | Deleted
        [ChangesJson] NVARCHAR(MAX)    NULL,           -- {"Prop":{"from":..,"to":..}} or {"Prop":value}
        [CreatedAt]   DATETIME2        NOT NULL CONSTRAINT [DF_AuditLogs_CreatedAt] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_AuditLogs] PRIMARY KEY CLUSTERED ([Id])
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLogs_Hospital_CreatedAt' AND object_id = OBJECT_ID('dbo.AuditLogs'))
    CREATE INDEX [IX_AuditLogs_Hospital_CreatedAt] ON [dbo].[AuditLogs] ([HospitalId], [CreatedAt] DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLogs_Entity' AND object_id = OBJECT_ID('dbo.AuditLogs'))
    CREATE INDEX [IX_AuditLogs_Entity] ON [dbo].[AuditLogs] ([HospitalId], [EntityType], [EntityId]);
GO
