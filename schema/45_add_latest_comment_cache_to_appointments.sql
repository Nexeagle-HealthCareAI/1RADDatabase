-- Migration: 45_add_latest_comment_cache_to_appointments.sql
-- Description: Denormalises the latest AppointmentComment's author name and
--              timestamp onto the Appointments row so the worklist can show
--              "by {name} · {when}" inline without joining Users + a per-row
--              subquery on every read. The full timeline view still resolves
--              authors via Users for accuracy; this is purely a read-cache
--              for the "latest" display.
--
--              Stale-name caveat: if a user later changes their FullName, the
--              denormalised column keeps the historical name. That's actually
--              the right behaviour for audit ("who said this AT THE TIME?")
--              and matches how invoices / commissions snapshot names.

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'LatestCommentAuthorName'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [LatestCommentAuthorName] NVARCHAR(255) NULL;
    PRINT 'Column dbo.Appointments.LatestCommentAuthorName added.';
END
ELSE
BEGIN
    PRINT 'Column dbo.Appointments.LatestCommentAuthorName already exists - skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'LatestCommentAt'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [LatestCommentAt] DATETIME2 NULL;
    PRINT 'Column dbo.Appointments.LatestCommentAt added.';
END
ELSE
BEGIN
    PRINT 'Column dbo.Appointments.LatestCommentAt already exists - skipped.';
END
GO

-- Appointments now carries a filtered index (IX_Appointments_Overdue_Active
-- from migration 42). SQL Server requires QUOTED_IDENTIFIER ON for any DML
-- against tables with filtered indexes; the CI sqlcmd session defaults to
-- OFF and trips Msg 1934. Setting it in its own batch scopes the change
-- correctly without leaking into other migration files.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Backfill the cache from the most recent comment for each appointment so
-- existing rows immediately show "by {name} · {when}". Without this, the
-- worklist would render empty author info until each appointment receives a
-- fresh comment. Re-runnable: the WHERE LatestCommentAt IS NULL guard means
-- a second execution is a no-op if every row was already backfilled.
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'AppointmentComments')
BEGIN
    WITH LatestPerAppt AS (
        SELECT
            c.AppointmentId,
            c.CreatedAt,
            c.AuthorUserId,
            ROW_NUMBER() OVER (PARTITION BY c.AppointmentId ORDER BY c.CreatedAt DESC) AS rn
        FROM [dbo].[AppointmentComments] c
    )
    UPDATE a
    SET
        a.LatestCommentAt = lp.CreatedAt,
        a.LatestCommentAuthorName = ISNULL(u.FullName, 'System')
    FROM [dbo].[Appointments] a
    INNER JOIN LatestPerAppt lp ON lp.AppointmentId = a.AppointmentId AND lp.rn = 1
    LEFT JOIN [dbo].[Users] u    ON u.UserId = lp.AuthorUserId
    WHERE a.LatestCommentAt IS NULL;

    PRINT 'Backfilled latest-comment cache from existing AppointmentComments.';
END
GO
