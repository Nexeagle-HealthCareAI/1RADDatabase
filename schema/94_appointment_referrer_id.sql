-- ============================================================
-- Migration 94 - Appointments.ReferrerId (the referring partner as a real key)
--
-- An appointment used to record its referring partner only as a NAME
-- (Appointments.ReferredBy). Renaming a partner - fixing a typo, adding a
-- title - therefore orphaned every earlier visit: the visits still carried
-- the old spelling, matched no partner record any more, and dropped out of
-- that partner's Source Analytics, exports and volume matrix.
--
-- This adds Appointments.ReferrerId (nullable, no foreign key on purpose -
-- a dangling id must never block a write; reports fall back to the name)
-- and backfills it from the existing name.
--
--   Backfill rules
--     * Only rows with no ReferrerId yet, so the script is safe to re-run.
--     * Matched inside the SAME centre (HospitalId) on the trimmed name,
--       case-insensitively - the same rule the reports use today.
--     * "Self" / walk-in and blank names stay NULL (they are not a partner).
--     * Two records with the same name in one centre (a live one and a
--       deleted one): the live record wins, then the lowest id - the same
--       tie-break the reports use, so nothing moves between partners.
--     * Names that match no partner stay NULL; they keep reporting as
--       "unlinked" exactly as before. The counts are printed below.
--     * UpdatedAt is NOT touched (this is a data repair, not an edit), so no
--       device is told the visit changed.
--
-- DEPLOY ORDER: apply this BEFORE the API release that reads the column.
-- Adding the column is harmless to the old API (it never names it), but the
-- new API selects it on every appointment query and would fail without it.
-- ============================================================

-- Appointments carries filtered indexes; SQL Server requires QUOTED_IDENTIFIER
-- ON for DDL/DML against such tables (the CI sqlcmd session defaults to OFF
-- and trips Msg 1934 - see migration 91).
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH(N'[dbo].[Appointments]', N'ReferrerId') IS NULL
BEGIN
    ALTER TABLE [dbo].[Appointments] ADD [ReferrerId] UNIQUEIDENTIFIER NULL;
    PRINT 'Column Appointments.ReferrerId added.';
END
ELSE PRINT 'Column Appointments.ReferrerId already exists - skipped.';
GO

-- Backfill --------------------------------------------------------------------
IF OBJECT_ID(N'tempdb..#ReferrerMap') IS NOT NULL DROP TABLE #ReferrerMap;

;WITH candidates AS (
    SELECT a.[AppointmentId],
           r.[ReferrerId],
           ROW_NUMBER() OVER (
               PARTITION BY a.[AppointmentId]
               ORDER BY CASE WHEN r.[DeletedAt] IS NULL THEN 0 ELSE 1 END, r.[ReferrerId]
           ) AS rn
    FROM [dbo].[Appointments] a
    JOIN [dbo].[Referrers] r
      ON r.[HospitalId] = a.[HospitalId]
     AND LTRIM(RTRIM(r.[Name])) = LTRIM(RTRIM(a.[ReferredBy]))
    WHERE a.[ReferrerId] IS NULL
      AND a.[ReferredBy] IS NOT NULL
      AND LTRIM(RTRIM(a.[ReferredBy])) <> N''
      AND LTRIM(RTRIM(a.[ReferredBy])) <> N'Self'
)
SELECT [AppointmentId], [ReferrerId]
INTO #ReferrerMap
FROM candidates
WHERE rn = 1;

CREATE UNIQUE CLUSTERED INDEX IX_ReferrerMap ON #ReferrerMap ([AppointmentId]);

DECLARE @matched INT = (SELECT COUNT(*) FROM #ReferrerMap);
DECLARE @done INT = 0, @batch INT = 1;

-- In batches so a large table never builds one huge transaction.
WHILE @batch > 0
BEGIN
    UPDATE TOP (5000) a
       SET a.[ReferrerId] = m.[ReferrerId]
      FROM [dbo].[Appointments] a
      JOIN #ReferrerMap m ON m.[AppointmentId] = a.[AppointmentId]
     WHERE a.[ReferrerId] IS NULL;
    SET @batch = @@ROWCOUNT;
    SET @done = @done + @batch;
END

PRINT CONCAT('Appointments linked to a partner by name: ', @done, ' (of ', @matched, ' matched).');
DROP TABLE #ReferrerMap;

DECLARE @unmatched INT = (
    SELECT COUNT(*) FROM [dbo].[Appointments]
    WHERE [ReferrerId] IS NULL
      AND [ReferredBy] IS NOT NULL
      AND LTRIM(RTRIM([ReferredBy])) <> N''
      AND LTRIM(RTRIM([ReferredBy])) <> N'Self');
PRINT CONCAT('Appointments naming a referrer with no partner record (left unlinked, unchanged): ', @unmatched);
GO

-- Index -----------------------------------------------------------------------
-- Single-partner drill-downs, rename propagation and per-partner counts filter
-- on (HospitalId, ReferrerId).
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_Appointments_Hospital_Referrer'
      AND object_id = OBJECT_ID(N'[dbo].[Appointments]')
)
BEGIN
    CREATE INDEX [IX_Appointments_Hospital_Referrer]
        ON [dbo].[Appointments] ([HospitalId], [ReferrerId])
        INCLUDE ([DateTime]);
    PRINT 'Index IX_Appointments_Hospital_Referrer created.';
END
ELSE PRINT 'Index IX_Appointments_Hospital_Referrer already exists - skipped.';
GO
