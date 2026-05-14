/* =========================================================
   1Rad / Clinical Core
   DDL Script: Linking Service Charges to Reporting Templates
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Add TemplateId column to ServiceCharges
IF COL_LENGTH('dbo.ServiceCharges', 'TemplateId') IS NULL
BEGIN
    ALTER TABLE [dbo].[ServiceCharges]
    ADD [TemplateId] UNIQUEIDENTIFIER NULL;
END
GO

-- 2. Add Foreign Key Constraint
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ServiceCharges_ReportTemplates')
BEGIN
    ALTER TABLE [dbo].[ServiceCharges]
    ADD CONSTRAINT [FK_ServiceCharges_ReportTemplates] 
    FOREIGN KEY ([TemplateId]) REFERENCES [dbo].[ReportTemplates] ([Id])
    ON DELETE SET NULL;
END
GO

-- 3. Create Index for faster lookups
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ServiceCharges_TemplateId' AND object_id = OBJECT_ID('dbo.ServiceCharges'))
BEGIN
    CREATE INDEX [IX_ServiceCharges_TemplateId] ON [dbo].[ServiceCharges] ([TemplateId]);
END
GO
