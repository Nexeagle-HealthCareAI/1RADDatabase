-- Rollback for schema/99_job_runs.sql
IF OBJECT_ID('dbo.JobRuns', 'U') IS NOT NULL DROP TABLE [dbo].[JobRuns];
GO
