-- ============================================================
-- Migration 98 - StudyAnnotations: viewer measurements that survive a reload
-- (gap analysis P3-7)
--
-- One row per study per centre. StudyKey = 'appointment:<guid>' or 'study:<guid>'
-- (ImagingStudies.Id). AnnotationsJson holds the viewer's Cornerstone annotations,
-- each tagged with its SOP Instance UID so it re-attaches to the right slice even
-- though image URLs change between sessions.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.StudyAnnotations', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[StudyAnnotations] (
        [Id]              UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_StudyAnnotations_Id] DEFAULT (NEWID()),
        [HospitalId]      UNIQUEIDENTIFIER NOT NULL,
        [StudyKey]        NVARCHAR(80)     NOT NULL,
        [AnnotationsJson] NVARCHAR(MAX)    NOT NULL CONSTRAINT [DF_StudyAnnotations_Json] DEFAULT (N'[]'),
        [AnnotationCount] INT              NOT NULL CONSTRAINT [DF_StudyAnnotations_Count] DEFAULT (0),
        [UpdatedByUserId] UNIQUEIDENTIFIER NULL,
        [UpdatedAt]       DATETIME2        NOT NULL CONSTRAINT [DF_StudyAnnotations_UpdatedAt] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_StudyAnnotations] PRIMARY KEY CLUSTERED ([Id])
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_StudyAnnotations_Hospital_Key' AND object_id = OBJECT_ID('dbo.StudyAnnotations'))
    CREATE UNIQUE INDEX [UX_StudyAnnotations_Hospital_Key] ON [dbo].[StudyAnnotations] ([HospitalId], [StudyKey]);
GO
