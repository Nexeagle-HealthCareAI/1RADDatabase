-- ============================================================
-- Migration 90 — Hospital Geolocation
-- Adds an optional GPS pin (Latitude/Longitude) per centre, set from the
-- centre's own settings page (GPS auto-detect or a draggable map pin).
-- Both columns stay NULL until an admin sets a location — never inferred.
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Hospitals') AND name = 'Latitude')
    ALTER TABLE Hospitals ADD Latitude DECIMAL(9,6) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Hospitals') AND name = 'Longitude')
    ALTER TABLE Hospitals ADD Longitude DECIMAL(9,6) NULL;

PRINT 'Migration 90 applied: Hospitals geolocation columns added.';
