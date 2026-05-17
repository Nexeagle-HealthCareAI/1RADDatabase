/* =========================================================
   1Rad / Clinical Core
   DDL Script: Daily Token Number — Persistent Appointment Sequencing
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Add DailyTokenNumber column to Appointments (idempotent)
IF COL_LENGTH('dbo.Appointments', 'DailyTokenNumber') IS NULL
BEGIN
    ALTER TABLE [dbo].[Appointments]
    ADD [DailyTokenNumber] INT NULL;

    PRINT 'Column DailyTokenNumber added successfully.';
END
ELSE
BEGIN
    PRINT 'Column DailyTokenNumber already exists. Skipping ALTER.';
END
GO

-- 2. Back-fill existing appointments with sequential tokens
--    Partitioned per HospitalId + Date, ordered by DateTime ASC.
--    Only fills rows where DailyTokenNumber is currently NULL (safe to re-run).
;WITH Ranked AS (
    SELECT
        AppointmentId,
        DailyTokenNumber,
        ROW_NUMBER() OVER (
            PARTITION BY HospitalId, CAST(DateTime AS DATE)
            ORDER BY DateTime ASC
        ) AS ComputedToken
    FROM [dbo].[Appointments]
)
UPDATE Ranked
SET DailyTokenNumber = ComputedToken
WHERE DailyTokenNumber IS NULL;
GO

PRINT 'Back-fill complete. All existing appointments now have a DailyTokenNumber.';
GO
