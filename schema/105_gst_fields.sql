-- ============================================================
-- Migration 105 - GST on services and bill lines (review B10, B33)
-- ServiceCharges carry the SAC code and GST rate; each bill line stamps them when
-- it is billed, so a later change never alters an issued bill. Prices stay
-- GST-inclusive: the printed bill splits the tax out. Diagnostic services are
-- normally exempt (SAC 9993, 0%), which is the default.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF COL_LENGTH('dbo.ServiceCharges', 'SacCode') IS NULL
    ALTER TABLE [dbo].[ServiceCharges] ADD [SacCode] NVARCHAR(8) NULL;
GO
IF COL_LENGTH('dbo.ServiceCharges', 'GstRate') IS NULL
    ALTER TABLE [dbo].[ServiceCharges] ADD [GstRate] DECIMAL(5,2) NOT NULL CONSTRAINT [DF_ServiceCharges_GstRate] DEFAULT (0);
GO
IF COL_LENGTH('dbo.InvoiceItems', 'SacCode') IS NULL
    ALTER TABLE [dbo].[InvoiceItems] ADD [SacCode] NVARCHAR(8) NULL;
GO
IF COL_LENGTH('dbo.InvoiceItems', 'GstRate') IS NULL
    ALTER TABLE [dbo].[InvoiceItems] ADD [GstRate] DECIMAL(5,2) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ServiceCharges_GstRate')
    ALTER TABLE [dbo].[ServiceCharges] ADD CONSTRAINT [CK_ServiceCharges_GstRate] CHECK ([GstRate] IN (0, 5, 12, 18, 28));
GO
PRINT 'Migration 105 applied: GST fields.';
GO
