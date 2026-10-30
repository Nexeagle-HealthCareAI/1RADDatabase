-- Rollback for schema/96_entity_schema_drift_fix.sql
-- WARNING: the API code requires these columns; only roll back together with an API
-- version that does not map them.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StaffLeaveRequests_SourceDisbursementId'
           AND object_id = OBJECT_ID('dbo.StaffLeaveRequests'))
    DROP INDEX [IX_StaffLeaveRequests_SourceDisbursementId] ON [dbo].[StaffLeaveRequests];
GO
IF COL_LENGTH('dbo.StaffLeaveRequests', 'SourceDisbursementId') IS NOT NULL
    ALTER TABLE [dbo].[StaffLeaveRequests] DROP COLUMN [SourceDisbursementId];
GO
DECLARE @c SYSNAME, @sql NVARCHAR(400);
DECLARE cols CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM (VALUES ('InputTokens'),('OutputTokens'),('CacheReadInputTokens'),
                             ('CacheHit'),('SavedInputTokens'),('SavedOutputTokens'),('Model')) v(name);
OPEN cols; FETCH NEXT FROM cols INTO @c;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF COL_LENGTH('dbo.RadAiQuestionLogs', @c) IS NOT NULL
    BEGIN
        SELECT @sql = N'ALTER TABLE [dbo].[RadAiQuestionLogs] DROP CONSTRAINT ' + QUOTENAME(dc.name)
        FROM sys.default_constraints dc
        JOIN sys.columns col ON col.default_object_id = dc.object_id
        WHERE col.object_id = OBJECT_ID('dbo.RadAiQuestionLogs') AND col.name = @c;
        IF @sql IS NOT NULL EXEC sp_executesql @sql;
        SET @sql = N'ALTER TABLE [dbo].[RadAiQuestionLogs] DROP COLUMN ' + QUOTENAME(@c);
        EXEC sp_executesql @sql;
        SET @sql = NULL;
    END
    FETCH NEXT FROM cols INTO @c;
END
CLOSE cols; DEALLOCATE cols;
GO
