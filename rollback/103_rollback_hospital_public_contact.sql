-- Rollback for 103.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF COL_LENGTH('dbo.Hospitals', 'PublicEmail') IS NOT NULL ALTER TABLE [dbo].[Hospitals] DROP COLUMN [PublicEmail];
GO
IF COL_LENGTH('dbo.Hospitals', 'PublicContact') IS NOT NULL ALTER TABLE [dbo].[Hospitals] DROP COLUMN [PublicContact];
GO
