-- Migration: 41_add_priority_to_appointments.sql
-- Description: Adds a clinical-urgency Priority column to Appointments.
--              STAT > URGENT > ROUTINE drives worklist sort order so STATs
--              surface at the top regardless of scheduled time. Editable
--              after booking. Existing rows default to ROUTINE.

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Appointments]') AND name = 'Priority'
)
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [Priority] NVARCHAR(16) NULL;

    -- Backfill every existing row with the default value so the column can be
    -- made NOT NULL and worklist sorting always has a value to rank by.
    EXEC('UPDATE [dbo].[Appointments] SET [Priority] = ''ROUTINE'' WHERE [Priority] IS NULL;');

    ALTER TABLE [dbo].[Appointments] ALTER COLUMN [Priority] NVARCHAR(16) NOT NULL;

    PRINT 'Column dbo.Appointments.Priority added and backfilled successfully.';
END
ELSE
BEGIN
    PRINT 'Column dbo.Appointments.Priority already exists - skipped.';
END
GO

-- Index for the worklist sort. The query orders by a CASE expression
-- (STAT/URGENT/ROUTINE rank) then DateTime, scoped per hospital. An index
-- on (HospitalId, Priority, DateTime) gives the query planner a clean covering
-- path for the common worklist read.
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Appointments_HospitalId_Priority_DateTime'
      AND object_id = OBJECT_ID(N'[dbo].[Appointments]')
)
BEGIN
    CREATE INDEX [IX_Appointments_HospitalId_Priority_DateTime]
        ON [dbo].[Appointments] ([HospitalId], [Priority], [DateTime]);
    PRINT 'Index IX_Appointments_HospitalId_Priority_DateTime created.';
END
ELSE
BEGIN
    PRINT 'Index IX_Appointments_HospitalId_Priority_DateTime already exists - skipped.';
END
GO
