-- Rollback for schema/100_rate_limit_counters.sql
IF OBJECT_ID('dbo.RateLimitCounters', 'U') IS NOT NULL DROP TABLE [dbo].[RateLimitCounters];
GO
