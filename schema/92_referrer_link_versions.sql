SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Migration: 92_referrer_link_versions.sql
-- Description: Per-partner "link version" for the public doctor portal so a partner's
--              portal links can be revoked individually and instantly.
--
--   Portal links are signed, stateless tokens. Each carries the version it was issued
--   under; the API only accepts a token whose version matches the row here. Bumping
--   Version (POST /referrers/{id}/revoke-links) invalidates every older link for that
--   partner. A partner with NO row is at version 0 - which is also what every link
--   issued before this table existed carries - so applying this script changes nothing
--   until someone actually revokes.
--
--   A separate table (rather than a column on Referrers) on purpose: the API only reads
--   it on the portal / link endpoints, so it is safe to deploy in either order relative
--   to the API - a missing table can only affect those endpoints, never referrer lookups.

IF OBJECT_ID(N'[dbo].[ReferrerLinkVersions]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[ReferrerLinkVersions] (
        [ReferrerId]      UNIQUEIDENTIFIER NOT NULL,
        [HospitalId]      UNIQUEIDENTIFIER NOT NULL,
        [Version]         INT              NOT NULL CONSTRAINT [DF_ReferrerLinkVersions_Version] DEFAULT (0),
        [RevokedAt]       DATETIME2        NULL,
        [RevokedByUserId] UNIQUEIDENTIFIER NULL,
        CONSTRAINT [PK_ReferrerLinkVersions] PRIMARY KEY CLUSTERED ([ReferrerId]),
        CONSTRAINT [FK_ReferrerLinkVersions_Referrers] FOREIGN KEY ([ReferrerId]) REFERENCES [dbo].[Referrers]([ReferrerId])
    );

    PRINT 'Table dbo.ReferrerLinkVersions created.';
END
ELSE
BEGIN
    PRINT 'Table dbo.ReferrerLinkVersions already exists - skipped.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_ReferrerLinkVersions_HospitalId'
                 AND object_id = OBJECT_ID(N'[dbo].[ReferrerLinkVersions]'))
BEGIN
    CREATE INDEX [IX_ReferrerLinkVersions_HospitalId] ON [dbo].[ReferrerLinkVersions] ([HospitalId]);
    PRINT 'Index IX_ReferrerLinkVersions_HospitalId created.';
END
ELSE
BEGIN
    PRINT 'Index IX_ReferrerLinkVersions_HospitalId already exists - skipped.';
END
GO
