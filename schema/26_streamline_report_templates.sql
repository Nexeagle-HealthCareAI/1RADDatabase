/* =========================================================
   1Rad / Clinical Reporting Intelligence
   DDL Script: Streamlining Report Templates
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Remove IsStructured column from ReportTemplates
IF COL_LENGTH('dbo.ReportTemplates', 'IsStructured') IS NOT NULL
BEGIN
    ALTER TABLE [dbo].[ReportTemplates] DROP COLUMN [IsStructured];
END
GO

-- 2. Remove DoctorId column from ReportTemplates
IF COL_LENGTH('dbo.ReportTemplates', 'DoctorId') IS NOT NULL
BEGIN
    -- Drop foreign key constraint if it exists (assuming it follows naming convention or just trying to drop)
    -- Usually better to check for constraint name if known, but let's try to drop the column directly if no FK is strictly enforced or just drop column
    -- If there's an FK, SQL will throw error. Let's be safe.
    
    DECLARE @ConstraintName nvarchar(200)
    SELECT @ConstraintName = name
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID('dbo.ReportTemplates')
    AND name LIKE '%Doctor%'

    IF @ConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE [dbo].[ReportTemplates] DROP CONSTRAINT ' + @ConstraintName)
    END

    ALTER TABLE [dbo].[ReportTemplates] DROP COLUMN [DoctorId];
END
GO
