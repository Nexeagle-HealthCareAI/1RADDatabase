-- ============================================================
-- 117 MONEY, PHASE 2: CLOSING THE DAY PROPERLY
-- Mirrors the new DayClose properties (ApplicationDbContext).
--
--  OpeningFloat      cash left in the drawer by the previous close
--  ExpectedBank      bank transfers that day (BANK is its own mode since 116)
--  NoteCounts        what was counted, note by note, as JSON {"500":30,"200":12,...,"coins":40}
--  DifferenceReason  why counted ≠ expected (required by the API when they differ)
--  FloatKept         cash left in the drawer for tomorrow
--  HandedOver        counted − float kept: cash taken out of the drawer
--  HandedTo          who took it (owner, bank deposit …)
--
-- Expected cash in the drawer is now OpeningFloat + the day's net cash. Older rows
-- have OpeningFloat 0, so their Variance keeps its meaning.
-- Requires 104. Safe to run more than once.
-- Rollback: rollback/117_rollback_day_close_float_and_count.sql
-- ============================================================
SET NOCOUNT ON;

IF OBJECT_ID('dbo.DayCloses', 'U') IS NULL
    THROW 51170, 'Run 104 first (DayCloses).', 1;

IF COL_LENGTH('dbo.DayCloses', 'OpeningFloat') IS NULL
    ALTER TABLE dbo.DayCloses ADD OpeningFloat DECIMAL(18,2) NOT NULL CONSTRAINT DF_DayCloses_OpeningFloat DEFAULT 0;
IF COL_LENGTH('dbo.DayCloses', 'ExpectedBank') IS NULL
    ALTER TABLE dbo.DayCloses ADD ExpectedBank DECIMAL(18,2) NOT NULL CONSTRAINT DF_DayCloses_ExpectedBank DEFAULT 0;
IF COL_LENGTH('dbo.DayCloses', 'NoteCounts') IS NULL
    ALTER TABLE dbo.DayCloses ADD NoteCounts NVARCHAR(400) NULL;
IF COL_LENGTH('dbo.DayCloses', 'DifferenceReason') IS NULL
    ALTER TABLE dbo.DayCloses ADD DifferenceReason NVARCHAR(120) NULL;
IF COL_LENGTH('dbo.DayCloses', 'FloatKept') IS NULL
    ALTER TABLE dbo.DayCloses ADD FloatKept DECIMAL(18,2) NOT NULL CONSTRAINT DF_DayCloses_FloatKept DEFAULT 0;
IF COL_LENGTH('dbo.DayCloses', 'HandedOver') IS NULL
    ALTER TABLE dbo.DayCloses ADD HandedOver DECIMAL(18,2) NOT NULL CONSTRAINT DF_DayCloses_HandedOver DEFAULT 0;
IF COL_LENGTH('dbo.DayCloses', 'HandedTo') IS NULL
    ALTER TABLE dbo.DayCloses ADD HandedTo NVARCHAR(100) NULL;

PRINT 'Migration 117 applied: day close with opening float, note count, reason, float kept and hand-over.';
