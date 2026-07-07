/* =========================================================
   1Rad / Clinical Command Hub
   Add Block to Patients
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.Patients', 'Block') IS NULL
BEGIN
    ALTER TABLE dbo.Patients ADD [Block] NVARCHAR(100) NULL;
END
GO
