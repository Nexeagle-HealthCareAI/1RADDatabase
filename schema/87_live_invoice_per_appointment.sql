-- Prevent a concurrent arrival action from creating two active invoices for
-- the same appointment. Soft-deleted invoices remain in the audit trail and
-- do not block the next arrival-driven invoice.
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_Invoices_Live_Appointment'
      AND object_id = OBJECT_ID(N'[dbo].[Invoices]')
)
BEGIN
    IF EXISTS (
        SELECT [AppointmentId]
        FROM [dbo].[Invoices]
        WHERE [AppointmentId] IS NOT NULL
          AND [DeletedAt] IS NULL
        GROUP BY [AppointmentId]
        HAVING COUNT(*) > 1
    )
    BEGIN
        THROW 51000, 'Cannot create UX_Invoices_Live_Appointment because duplicate live invoices exist. Resolve duplicates before retrying this migration.', 1;
    END;

    CREATE UNIQUE INDEX [UX_Invoices_Live_Appointment]
        ON [dbo].[Invoices] ([AppointmentId])
        WHERE [AppointmentId] IS NOT NULL AND [DeletedAt] IS NULL;

    PRINT 'Created UX_Invoices_Live_Appointment.';
END
ELSE
BEGIN
    PRINT 'UX_Invoices_Live_Appointment already exists.';
END;
GO
