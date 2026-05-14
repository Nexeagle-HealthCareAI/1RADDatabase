/* =========================================================
   1Rad / Clinical Reporting Intelligence
   DDL Script: Keyword Categorization Support
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Add Category column to ReportingKeywords
IF COL_LENGTH('dbo.ReportingKeywords', 'Category') IS NULL
BEGIN
    ALTER TABLE [dbo].[ReportingKeywords]
    ADD [Category] NVARCHAR(100) DEFAULT '' NOT NULL;
END
GO

-- 2. Create Index for faster grouping/searching by Category
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ReportingKeywords_Category' AND object_id = OBJECT_ID('dbo.ReportingKeywords'))
BEGIN
    CREATE INDEX [IX_ReportingKeywords_Category] ON [dbo].[ReportingKeywords] ([Category]);
END
GO
