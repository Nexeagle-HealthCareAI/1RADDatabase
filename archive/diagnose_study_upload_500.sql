-- =========================================================================
-- DIAGNOSTIC: Why does POST /Study/upload return 500?
-- Run against the Azure SQL database (easyhmserver). Read-only — it only
-- reports which StudyAssets columns are missing. If any row below reports
-- 'MISSING', that unapplied schema is the cause of the upload 500
-- (EF insert fails on the missing column → "INTERNAL ACQUISITION FAILURE").
--
-- FIX: apply oneRadDB/schema/39_dicom_extraction_pipeline.sql and
--      oneRadDB/schema/57_appointment_services.sql (both idempotent).
-- =========================================================================

SELECT col,
       CASE WHEN EXISTS (
            SELECT 1 FROM sys.columns
            WHERE Object_ID = Object_ID(N'dbo.StudyAssets') AND Name = col
       ) THEN 'OK' ELSE 'MISSING — apply migration' END AS status
FROM (VALUES
    (N'AppointmentServiceId'),   -- migration 57
    (N'ExtractionStatus'),       -- migration 39
    (N'ExtractionStartedAt'),    -- migration 39
    (N'ExtractionCompletedAt'),  -- migration 39
    (N'ExtractionError'),        -- migration 39
    (N'ExtractionSliceCount')    -- migration 39
) AS required(col);

-- StudySliceIndexes table (migration 39) — used by the viewer manifest path.
SELECT CASE WHEN OBJECT_ID(N'dbo.StudySliceIndexes', N'U') IS NULL
            THEN 'StudySliceIndexes: MISSING — apply migration 39'
            ELSE 'StudySliceIndexes: OK' END AS slice_table_status;
