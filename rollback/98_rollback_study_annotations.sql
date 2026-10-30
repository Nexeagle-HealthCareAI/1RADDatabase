-- Rollback for schema/98_study_annotations.sql — deletes saved viewer measurements.
IF OBJECT_ID('dbo.StudyAnnotations', 'U') IS NOT NULL DROP TABLE [dbo].[StudyAnnotations];
GO
