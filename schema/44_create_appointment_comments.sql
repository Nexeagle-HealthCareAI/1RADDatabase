-- Migration: 44_create_appointment_comments.sql
-- Description: Adds an audit-friendly comment trail for each Appointment.
--              Previously the single Appointments.DelayReason column was
--              overwritten on every edit, so prior context was lost. The new
--              AppointmentComments table appends each entry as its own row
--              with author + timestamp. DelayReason is kept as a denormalised
--              cache of the LATEST comment so worklist rows can show it
--              without joining (one column read).
--
--              Read path:
--                row display  → appointments.DelayReason  (latest, fast)
--                history view → /appointments/{id}/comments  (full timeline)
--              Write path:
--                POST /appointments/{id}/comments
--                  inserts a row + updates appointments.DelayReason atomically.

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AppointmentComments')
BEGIN
    CREATE TABLE [dbo].[AppointmentComments] (
        [AppointmentCommentId] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [PK_AppointmentComments] PRIMARY KEY,
        [AppointmentId]        UNIQUEIDENTIFIER NOT NULL,
        [HospitalId]           UNIQUEIDENTIFIER NOT NULL,
        [Body]                 NVARCHAR(2000)   NOT NULL,
        [AuthorUserId]         UNIQUEIDENTIFIER NULL,
        [CreatedAt]            DATETIME2        NOT NULL CONSTRAINT [DF_AppointmentComments_CreatedAt] DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT [FK_AppointmentComments_Appointments]
            FOREIGN KEY ([AppointmentId]) REFERENCES [dbo].[Appointments]([AppointmentId])
            ON DELETE CASCADE
    );

    -- Timeline read pattern: scoped per appointment, newest first. The
    -- compound index makes the "show all comments for this appointment"
    -- query a single seek + ordered range scan.
    CREATE INDEX [IX_AppointmentComments_AppointmentId_CreatedAt]
        ON [dbo].[AppointmentComments] ([AppointmentId], [CreatedAt] DESC);

    -- Hospital scoping for tenant-level audit queries / exports.
    CREATE INDEX [IX_AppointmentComments_HospitalId_CreatedAt]
        ON [dbo].[AppointmentComments] ([HospitalId], [CreatedAt] DESC);

    PRINT 'Table dbo.AppointmentComments created.';
END
ELSE
BEGIN
    PRINT 'Table dbo.AppointmentComments already exists - skipped.';
END
GO

-- Seed the new table from existing DelayReason values so the timeline isn't
-- empty for cases that already carry a comment. Each surviving DelayReason
-- becomes a single historical comment dated to the Appointment's own
-- CreatedAt (or now if not available) — close enough for audit; honest
-- because we don't know the real authorship.
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'AppointmentComments')
   AND EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'DelayReason')
BEGIN
    INSERT INTO [dbo].[AppointmentComments] (
        [AppointmentCommentId], [AppointmentId], [HospitalId], [Body], [AuthorUserId], [CreatedAt]
    )
    SELECT
        NEWID(),
        a.[AppointmentId],
        a.[HospitalId],
        a.[DelayReason],
        NULL,
        SYSUTCDATETIME()
    FROM [dbo].[Appointments] a
    LEFT JOIN [dbo].[AppointmentComments] c ON c.[AppointmentId] = a.[AppointmentId]
    WHERE a.[DelayReason] IS NOT NULL
      AND LTRIM(RTRIM(a.[DelayReason])) <> ''
      AND c.[AppointmentCommentId] IS NULL; -- only seed appointments that don't already have any comments

    PRINT 'Backfilled existing DelayReason values into AppointmentComments.';
END
GO
