-- Rollback for schema/101_integration_clients.sql — every issued integration key stops working.
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StudySliceIndexes_SeriesUID' AND object_id = OBJECT_ID('dbo.StudySliceIndexes'))
    DROP INDEX [IX_StudySliceIndexes_SeriesUID] ON [dbo].[StudySliceIndexes];
GO
IF OBJECT_ID('dbo.IntegrationClients', 'U') IS NOT NULL DROP TABLE [dbo].[IntegrationClients];
GO
