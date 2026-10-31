-- ============================================================
-- Migration 107 - ReferralPortalViews (review R9/R23)
-- One row each time a partner's portal link is opened or used, so the centre can
-- see when and how often a link is used. The IP address is stored as a hash.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF OBJECT_ID('dbo.ReferralPortalViews', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[ReferralPortalViews] (
        [Id]          UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ReferralPortalViews_Id] DEFAULT (NEWID()),
        [HospitalId]  UNIQUEIDENTIFIER NOT NULL,
        [ReferrerId]  UNIQUEIDENTIFIER NOT NULL,
        [ViewedAt]    DATETIME2        NOT NULL,
        [Action]      NVARCHAR(20)     NOT NULL,
        [IpHash]      NVARCHAR(64)     NULL,
        [UserAgent]   NVARCHAR(300)    NULL,
        [LinkVersion] INT              NOT NULL CONSTRAINT [DF_ReferralPortalViews_LinkVersion] DEFAULT (0),
        CONSTRAINT [PK_ReferralPortalViews] PRIMARY KEY CLUSTERED ([Id])
    );
    CREATE INDEX [IX_ReferralPortalViews_Hospital_Referrer_ViewedAt] ON [dbo].[ReferralPortalViews] ([HospitalId], [ReferrerId], [ViewedAt]);
END
GO
PRINT 'Migration 107 applied: ReferralPortalViews.';
GO
