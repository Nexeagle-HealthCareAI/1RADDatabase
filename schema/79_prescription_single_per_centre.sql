-- ════════════════════════════════════════════════════════════════════════════
--  79_prescription_single_per_centre.sql
--
--  Prescription / report-letterhead settings become ONE per diagnostic centre,
--  shared by every doctor (previously keyed per (DoctorId, HospitalId)).
--
--  Steps:
--    1. Collapse each hospital's protocols to a single row — keep the one that
--       has a letterhead (else the earliest-created = the centre's original
--       setup); delete the rest.
--    2. Drop the old composite unique index (DoctorId, HospitalId).
--    3. Add a unique index on HospitalId so a centre can only ever have one.
--
--  Run against your 1RadDb database. Idempotent — safe to re-run.
-- ════════════════════════════════════════════════════════════════════════════

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Collapse duplicates per hospital (keep letterhead-bearing, else earliest).
;WITH ranked AS (
    SELECT
        Id,
        ROW_NUMBER() OVER (
            PARTITION BY HospitalId
            ORDER BY
                CASE WHEN LetterheadBlobUrl IS NOT NULL AND LEN(LetterheadBlobUrl) > 0 THEN 0 ELSE 1 END,
                CreatedAt ASC
        ) AS rn
    FROM dbo.PrescriptionProtocols
)
DELETE FROM dbo.PrescriptionProtocols
WHERE Id IN (SELECT Id FROM ranked WHERE rn > 1);
PRINT '  ~ Collapsed PrescriptionProtocols to one row per hospital.';
GO

-- 2. Drop the old per-(doctor,hospital) unique index — multiple doctors per
--    hospital is no longer allowed.
IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE name = 'UIX_PrescriptionProtocols_Doctor_Hospital'
             AND object_id = OBJECT_ID('dbo.PrescriptionProtocols'))
BEGIN
    DROP INDEX [UIX_PrescriptionProtocols_Doctor_Hospital] ON dbo.PrescriptionProtocols;
    PRINT '  - Dropped UIX_PrescriptionProtocols_Doctor_Hospital';
END
ELSE PRINT '  = UIX_PrescriptionProtocols_Doctor_Hospital already absent.';
GO

-- 3. One protocol per centre.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'UX_PrescriptionProtocols_HospitalId'
                 AND object_id = OBJECT_ID('dbo.PrescriptionProtocols'))
BEGIN
    CREATE UNIQUE INDEX [UX_PrescriptionProtocols_HospitalId]
        ON dbo.PrescriptionProtocols ([HospitalId]);
    PRINT '  + Created UX_PrescriptionProtocols_HospitalId (one protocol per centre)';
END
ELSE PRINT '  = UX_PrescriptionProtocols_HospitalId already exists.';
GO
