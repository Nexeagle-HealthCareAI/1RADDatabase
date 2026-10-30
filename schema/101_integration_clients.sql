-- ============================================================
-- Migration 101 - IntegrationClients: API keys for outside systems
-- (gap analysis P3-6 — DICOMweb, modality worklist, FHIR)
--
-- A hospital HIS, a DICOMweb viewer (OHIF/Weasis), a modality or the on-prem
-- bridge cannot sign in with a staff OTP/password, so each centre's admin issues
-- keys here. A key belongs to ONE centre and only opens the integration endpoints
-- (api/v1/dicomweb, api/v1/worklist, api/v1/fhir) for the scopes it was given.
--
-- The secret is never stored: SecretHash is SHA-256 (hex) of the whole key. A key
-- looks like  1rk_<KeyId>_<secret>  and KeyId is the lookup column.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.IntegrationClients', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[IntegrationClients] (
        [Id]              UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_IntegrationClients_Id] DEFAULT (NEWID()),
        [HospitalId]      UNIQUEIDENTIFIER NOT NULL,
        [Name]            NVARCHAR(100)    NOT NULL,
        [KeyId]           NVARCHAR(16)     NOT NULL,   -- public part of the key, e.g. 'k7F3pQ9a'
        [SecretHash]      NVARCHAR(64)     NOT NULL,   -- SHA-256 hex of the full key
        [Scopes]          NVARCHAR(400)    NOT NULL,   -- comma list: dicomweb.read,dicomweb.write,worklist.read,fhir.read
        [CreatedByUserId] UNIQUEIDENTIFIER NULL,
        [CreatedAt]       DATETIME2        NOT NULL CONSTRAINT [DF_IntegrationClients_CreatedAt] DEFAULT (SYSUTCDATETIME()),
        [LastUsedAt]      DATETIME2        NULL,
        [RevokedAt]       DATETIME2        NULL,
        CONSTRAINT [PK_IntegrationClients] PRIMARY KEY CLUSTERED ([Id])
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_IntegrationClients_KeyId' AND object_id = OBJECT_ID('dbo.IntegrationClients'))
    CREATE UNIQUE INDEX [UX_IntegrationClients_KeyId] ON [dbo].[IntegrationClients] ([KeyId]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_IntegrationClients_Hospital' AND object_id = OBJECT_ID('dbo.IntegrationClients'))
    CREATE INDEX [IX_IntegrationClients_Hospital] ON [dbo].[IntegrationClients] ([HospitalId], [CreatedAt]);
GO

-- DICOMweb lookups by Study Instance UID (QIDO/WADO) — ImagingStudies already has a
-- per-hospital unique index on the UID; series lookups go through the slice index.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StudySliceIndexes_SeriesUID' AND object_id = OBJECT_ID('dbo.StudySliceIndexes'))
    CREATE INDEX [IX_StudySliceIndexes_SeriesUID] ON [dbo].[StudySliceIndexes] ([HospitalId], [SeriesUID]) INCLUDE ([AssetId], [SopInstanceUID]);
GO
