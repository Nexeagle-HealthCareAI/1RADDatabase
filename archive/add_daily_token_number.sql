-- ============================================================
-- TOKEN NUMBER MIGRATION
-- Run this against your 1RadDb database
-- Safe to run multiple times (checks column existence first)
-- ============================================================

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Appointments' 
    AND COLUMN_NAME = 'DailyTokenNumber'
)
BEGIN
    ALTER TABLE Appointments
    ADD DailyTokenNumber INT NULL;

    PRINT 'Column DailyTokenNumber added successfully.';
END
ELSE
BEGIN
    PRINT 'Column DailyTokenNumber already exists. Skipping.';
END

-- Optional: Back-fill token numbers for existing appointments
-- This assigns sequential tokens per hospital + date based on creation order
-- Safe to run, does NOT overwrite appointments that already have a token
;WITH Ranked AS (
    SELECT 
        AppointmentId,
        DailyTokenNumber,
        ROW_NUMBER() OVER (
            PARTITION BY HospitalId, CAST(DateTime AS DATE)
            ORDER BY DateTime ASC
        ) AS ComputedToken
    FROM Appointments
)
UPDATE Ranked
SET DailyTokenNumber = ComputedToken
WHERE DailyTokenNumber IS NULL;

PRINT 'Back-fill complete. All existing appointments now have a DailyTokenNumber.';
