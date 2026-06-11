-- ============================================================
-- IMAGING STUDY — matching columns (Cloud PACS-only, Phase 2)
-- Run this against your 1RadDb database.
-- Safe to run multiple times — every step is idempotent.
--
-- Adds:
--   1. dbo.ImagingStudies.AccessionNumber  (DICOM 0008,0050 — the bridge sets
--      this to the 1Rad appointment id; server-side matching keys off it)
--   2. dbo.ImagingStudies.MatchStatus      (Unmatched | AutoMatched |
--      ManuallyAssigned — drives the PACS-only "unassigned" inbox)
-- Plus supporting indexes for the inbox slice and accession lookup.
-- ============================================================

SET NOCOUNT ON;
-- Filtered index below requires these ON (sqlcmd defaults them OFF without -I).
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'ImagingStudies'
      AND COLUMN_NAME = 'AccessionNumber'
)
BEGIN
    ALTER TABLE dbo.ImagingStudies
        ADD AccessionNumber NVARCHAR(64) NULL;
    PRINT '  + Added column dbo.ImagingStudies.AccessionNumber';
END
ELSE
    PRINT '  = Column dbo.ImagingStudies.AccessionNumber already exists.';
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'ImagingStudies'
      AND COLUMN_NAME = 'MatchStatus'
)
BEGIN
    ALTER TABLE dbo.ImagingStudies
        ADD MatchStatus NVARCHAR(20) NOT NULL
            CONSTRAINT DF_ImagingStudies_MatchStatus DEFAULT 'Unmatched';
    PRINT '  + Added column dbo.ImagingStudies.MatchStatus (default Unmatched)';
END
ELSE
    PRINT '  = Column dbo.ImagingStudies.MatchStatus already exists.';
GO

-- PACS-only inbox slice: unassigned studies for a hospital.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ImagingStudies_Hospital_MatchStatus' AND object_id = OBJECT_ID('dbo.ImagingStudies'))
BEGIN
    CREATE INDEX IX_ImagingStudies_Hospital_MatchStatus ON dbo.ImagingStudies (HospitalId, MatchStatus);
    PRINT '  + Created IX_ImagingStudies_Hospital_MatchStatus';
END
ELSE PRINT '  = IX_ImagingStudies_Hospital_MatchStatus already exists.';
GO

-- Accession lookup for server-side matching / reconciliation.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ImagingStudies_Hospital_Accession' AND object_id = OBJECT_ID('dbo.ImagingStudies'))
BEGIN
    CREATE INDEX IX_ImagingStudies_Hospital_Accession ON dbo.ImagingStudies (HospitalId, AccessionNumber)
        WHERE AccessionNumber IS NOT NULL;
    PRINT '  + Created IX_ImagingStudies_Hospital_Accession';
END
ELSE PRINT '  = IX_ImagingStudies_Hospital_Accession already exists.';
GO
