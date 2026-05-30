-- Migration: 46_add_session_management_to_refresh_tokens.sql
-- Description: Extends RefreshTokens with the columns + indexes the multi-
--              device session policy needs:
--                • SessionId      → stable per-session identifier (embedded as
--                                   the `sid` JWT claim) so the stateful
--                                   validation middleware can revoke a single
--                                   device without rotating the user's whole
--                                   token family.
--                • DeviceCategory → DESKTOP / MOBILE / TABLET / UNKNOWN. Drives
--                                   the "one per category, max three total"
--                                   cap and the per-row icon on Settings →
--                                   Active Sessions.
--                • DeviceName     → human display, e.g. "Chrome 120 on
--                                   Windows" or "iPhone 15 (Safari)".
--                • UserAgent      → raw UA string for audit + abuse triage.
--                • IpAddress      → 45-char field so IPv6 fits.
--                • LastSeenAt     → updated by the session middleware (throttled
--                                   to once per 30s per session) so the idle-
--                                   timeout sweeper and "last activity" UI
--                                   have a real signal to read.
--                • LoggedOutReason→ USER / FORCED_BY_NEW_DEVICE / EXPIRED /
--                                   IDLE_TIMEOUT / ADMIN / SUSPICIOUS. The
--                                   existing RevokedAt column already records
--                                   *when* — this records *why*.
--
--              All columns are additive + nullable; no backfill is forced.
--              Old RefreshTokens rows continue to work (the middleware will
--              just treat them as "no sid" → effectively single-shot, kicked
--              on next login of the same category). A separate one-off
--              housekeeping step (not in this script) can mark legacy rows
--              with LoggedOutReason='LEGACY' if you want them visible in audit.

-- Filtered-index batches below require QUOTED_IDENTIFIER. The deploy
-- pipeline's sqlcmd session defaults this OFF; setting it here scopes the
-- change to this file only.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ── Columns ──────────────────────────────────────────────────────────────

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[RefreshTokens]') AND name = 'SessionId'
)
BEGIN
    ALTER TABLE [dbo].[RefreshTokens] ADD [SessionId] UNIQUEIDENTIFIER NULL;
    PRINT 'Column dbo.RefreshTokens.SessionId added.';
END
ELSE PRINT 'Column dbo.RefreshTokens.SessionId already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[RefreshTokens]') AND name = 'DeviceCategory'
)
BEGIN
    ALTER TABLE [dbo].[RefreshTokens] ADD [DeviceCategory] NVARCHAR(20) NULL;
    PRINT 'Column dbo.RefreshTokens.DeviceCategory added.';
END
ELSE PRINT 'Column dbo.RefreshTokens.DeviceCategory already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[RefreshTokens]') AND name = 'DeviceName'
)
BEGIN
    ALTER TABLE [dbo].[RefreshTokens] ADD [DeviceName] NVARCHAR(100) NULL;
    PRINT 'Column dbo.RefreshTokens.DeviceName added.';
END
ELSE PRINT 'Column dbo.RefreshTokens.DeviceName already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[RefreshTokens]') AND name = 'UserAgent'
)
BEGIN
    ALTER TABLE [dbo].[RefreshTokens] ADD [UserAgent] NVARCHAR(512) NULL;
    PRINT 'Column dbo.RefreshTokens.UserAgent added.';
END
ELSE PRINT 'Column dbo.RefreshTokens.UserAgent already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[RefreshTokens]') AND name = 'IpAddress'
)
BEGIN
    -- 45 chars accommodates a full IPv6 + zone-id suffix.
    ALTER TABLE [dbo].[RefreshTokens] ADD [IpAddress] NVARCHAR(45) NULL;
    PRINT 'Column dbo.RefreshTokens.IpAddress added.';
END
ELSE PRINT 'Column dbo.RefreshTokens.IpAddress already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[RefreshTokens]') AND name = 'LastSeenAt'
)
BEGIN
    ALTER TABLE [dbo].[RefreshTokens] ADD [LastSeenAt] DATETIME2 NULL;
    PRINT 'Column dbo.RefreshTokens.LastSeenAt added.';
END
ELSE PRINT 'Column dbo.RefreshTokens.LastSeenAt already exists - skipped.';
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[RefreshTokens]') AND name = 'LoggedOutReason'
)
BEGIN
    ALTER TABLE [dbo].[RefreshTokens] ADD [LoggedOutReason] NVARCHAR(40) NULL;
    PRINT 'Column dbo.RefreshTokens.LoggedOutReason added.';
END
ELSE PRINT 'Column dbo.RefreshTokens.LoggedOutReason already exists - skipped.';
GO

-- ── Indexes ──────────────────────────────────────────────────────────────

-- Sole read path for the stateful JWT middleware: "is this sid still active?"
-- Hot. Filtered to active rows only so the index stays tiny even with years
-- of revoked history sitting in the table.
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_RefreshTokens_SessionId_Active'
      AND object_id = OBJECT_ID(N'[dbo].[RefreshTokens]')
)
BEGIN
    CREATE UNIQUE INDEX [IX_RefreshTokens_SessionId_Active]
        ON [dbo].[RefreshTokens] ([SessionId])
        WHERE [SessionId] IS NOT NULL AND [RevokedAt] IS NULL;
    PRINT 'Index IX_RefreshTokens_SessionId_Active created.';
END
ELSE PRINT 'Index IX_RefreshTokens_SessionId_Active already exists - skipped.';
GO

-- "List the active sessions for this user" + "is there already an active
-- session of this category to revoke?" — both run on login and on the
-- Active Sessions page. Filtered to active rows for the same reason as
-- above.
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_RefreshTokens_User_Category_Active'
      AND object_id = OBJECT_ID(N'[dbo].[RefreshTokens]')
)
BEGIN
    CREATE INDEX [IX_RefreshTokens_User_Category_Active]
        ON [dbo].[RefreshTokens] ([UserId], [DeviceCategory])
        INCLUDE ([SessionId], [DeviceName], [CreatedAt], [LastSeenAt])
        WHERE [RevokedAt] IS NULL;
    PRINT 'Index IX_RefreshTokens_User_Category_Active created.';
END
ELSE PRINT 'Index IX_RefreshTokens_User_Category_Active already exists - skipped.';
GO

-- Idle-timeout sweeper read path: "scan all active sessions whose LastSeenAt
-- is older than the idle threshold." Filtered + ordered by LastSeenAt so the
-- background job is a small range scan instead of a full table walk.
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_RefreshTokens_Idle_Sweep'
      AND object_id = OBJECT_ID(N'[dbo].[RefreshTokens]')
)
BEGIN
    CREATE INDEX [IX_RefreshTokens_Idle_Sweep]
        ON [dbo].[RefreshTokens] ([LastSeenAt])
        WHERE [RevokedAt] IS NULL AND [LastSeenAt] IS NOT NULL;
    PRINT 'Index IX_RefreshTokens_Idle_Sweep created.';
END
ELSE PRINT 'Index IX_RefreshTokens_Idle_Sweep already exists - skipped.';
GO
