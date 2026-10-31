SET QUOTED_IDENTIFIER ON;
GO
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ServiceCharges_GstRate') ALTER TABLE [dbo].[ServiceCharges] DROP CONSTRAINT [CK_ServiceCharges_GstRate];
GO
IF COL_LENGTH('dbo.InvoiceItems', 'GstRate') IS NOT NULL ALTER TABLE [dbo].[InvoiceItems] DROP COLUMN [GstRate];
GO
IF COL_LENGTH('dbo.InvoiceItems', 'SacCode') IS NOT NULL ALTER TABLE [dbo].[InvoiceItems] DROP COLUMN [SacCode];
GO
IF COL_LENGTH('dbo.ServiceCharges', 'GstRate') IS NOT NULL
BEGIN
    ALTER TABLE [dbo].[ServiceCharges] DROP CONSTRAINT [DF_ServiceCharges_GstRate];
    ALTER TABLE [dbo].[ServiceCharges] DROP COLUMN [GstRate];
END
GO
IF COL_LENGTH('dbo.ServiceCharges', 'SacCode') IS NOT NULL ALTER TABLE [dbo].[ServiceCharges] DROP COLUMN [SacCode];
GO
