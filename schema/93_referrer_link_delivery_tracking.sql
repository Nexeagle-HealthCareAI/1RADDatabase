SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Migration: 93_referrer_link_delivery_tracking.sql
-- Description: Delivery tracking + auto-renewal state for doctor-portal links, on the
--              ReferrerLinkVersions table created in 92.
--
--   Portal links now expire (90 days by default, ReferralLinks:TtlDays). Every deliberate
--   send - the Doctor Links tab's email / WhatsApp, a daily auto-renewal, or a doctor
--   asking for a fresh link - records:
--     LastSentAt         when it went out
--     LastSentChannel    'whatsapp' | 'email'
--     LastSentExpiresAt  expiry of the link that send carried
--     LastSentBaseUrl    the portal origin used (renewals reuse it; it is NEVER taken
--                        from a public request)
--     AutoRenew          whether the daily job should renew it before it expires
--                        (revoking a partner's links switches it off)
--
--   All columns are nullable / default 0, so applying this changes nothing by itself:
--   no link is auto-renewed until a centre sends one after the API ships.
--   Still only read by the portal / link endpoints and the renewal job, so a deploy-order
--   slip cannot affect referrer lookups app-wide.

IF COL_LENGTH(N'[dbo].[ReferrerLinkVersions]', N'LastSentAt') IS NULL
    ALTER TABLE [dbo].[ReferrerLinkVersions] ADD [LastSentAt] DATETIME2 NULL;
GO
IF COL_LENGTH(N'[dbo].[ReferrerLinkVersions]', N'LastSentChannel') IS NULL
    ALTER TABLE [dbo].[ReferrerLinkVersions] ADD [LastSentChannel] NVARCHAR(16) NULL;
GO
IF COL_LENGTH(N'[dbo].[ReferrerLinkVersions]', N'LastSentExpiresAt') IS NULL
    ALTER TABLE [dbo].[ReferrerLinkVersions] ADD [LastSentExpiresAt] DATETIME2 NULL;
GO
IF COL_LENGTH(N'[dbo].[ReferrerLinkVersions]', N'LastSentBaseUrl') IS NULL
    ALTER TABLE [dbo].[ReferrerLinkVersions] ADD [LastSentBaseUrl] NVARCHAR(300) NULL;
GO
IF COL_LENGTH(N'[dbo].[ReferrerLinkVersions]', N'AutoRenew') IS NULL
    ALTER TABLE [dbo].[ReferrerLinkVersions]
        ADD [AutoRenew] BIT NOT NULL CONSTRAINT [DF_ReferrerLinkVersions_AutoRenew] DEFAULT (0);
GO

-- The daily job scans for AutoRenew rows nearing expiry.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_ReferrerLinkVersions_AutoRenew_Expiry'
                 AND object_id = OBJECT_ID(N'[dbo].[ReferrerLinkVersions]'))
BEGIN
    CREATE INDEX [IX_ReferrerLinkVersions_AutoRenew_Expiry]
        ON [dbo].[ReferrerLinkVersions] ([LastSentExpiresAt])
        WHERE [AutoRenew] = 1;
    PRINT 'Index IX_ReferrerLinkVersions_AutoRenew_Expiry created.';
END
GO

PRINT 'Migration 93 applied: referrer link delivery tracking columns present.';
GO
