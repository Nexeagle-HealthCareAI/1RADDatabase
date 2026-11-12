-- Rollback for 117_day_close_float_and_count.sql. Roll the API back FIRST.
-- Drops the float, note counts, reasons and hand-over already recorded.
SET NOCOUNT ON;
DECLARE @c TABLE (col SYSNAME, df SYSNAME NULL);
INSERT @c VALUES ('OpeningFloat','DF_DayCloses_OpeningFloat'),('ExpectedBank','DF_DayCloses_ExpectedBank'),('NoteCounts',NULL),
                 ('DifferenceReason',NULL),('FloatKept','DF_DayCloses_FloatKept'),('HandedOver','DF_DayCloses_HandedOver'),('HandedTo',NULL);
DECLARE @col SYSNAME, @df SYSNAME;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT col, df FROM @c;
OPEN cur; FETCH NEXT FROM cur INTO @col, @df;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF COL_LENGTH('dbo.DayCloses', @col) IS NOT NULL
    BEGIN
        IF @df IS NOT NULL AND OBJECT_ID('dbo.' + @df, 'D') IS NOT NULL EXEC('ALTER TABLE dbo.DayCloses DROP CONSTRAINT ' + @df);
        EXEC('ALTER TABLE dbo.DayCloses DROP COLUMN ' + @col);
    END
    FETCH NEXT FROM cur INTO @col, @df;
END
CLOSE cur; DEALLOCATE cur;
PRINT 'Rolled back 117';
