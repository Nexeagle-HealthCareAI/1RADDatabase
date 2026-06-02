-- =========================================================================
-- MIGRATION: 60_patient_name_normalized.sql
-- Duplicate-detection safety net. Adds Patients.NameNormalized — a lowercased,
-- whitespace-collapsed copy of FullName the CreatePatient handler uses to
-- collapse casing/spacing/honorific variants of the same name (paired with an
-- exact phone match before it ever auto-merges).
--
-- The handler writes the fully-normalised value (honorifics stripped) on every
-- create/update; this script only backfills a rough lowercased/trimmed value so
-- the column and index aren't empty for legacy rows. Idempotent.
-- =========================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE Name = N'NameNormalized'
      AND Object_ID = Object_ID(N'dbo.Patients')
)
BEGIN
    ALTER TABLE [dbo].[Patients] ADD [NameNormalized] NVARCHAR(200) NULL;
    PRINT 'Added NameNormalized column to Patients.';
END
GO

-- Rough backfill for existing rows (lowercase + collapse outer whitespace).
-- The app refines this (honorific/punctuation stripping) the next time each
-- patient is touched; the CreatePatient dedup also falls back to an exact
-- FullName match, so legacy rows stay deduplicated in the meantime.
UPDATE [dbo].[Patients]
   SET [NameNormalized] = LTRIM(RTRIM(LOWER([FullName])))
 WHERE [NameNormalized] IS NULL
   AND [FullName] IS NOT NULL;
GO

-- Composite index to keep the dedup lookup (HospitalId + Mobile + NameNormalized) fast.
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE Name = N'IX_Patients_Dedup'
      AND Object_ID = Object_ID(N'dbo.Patients')
)
BEGIN
    CREATE INDEX [IX_Patients_Dedup]
        ON [dbo].[Patients] ([HospitalId], [Mobile], [NameNormalized]);
    PRINT 'Created index IX_Patients_Dedup.';
END
GO

PRINT '✅ Migration 60_patient_name_normalized.sql completed.';
GO
