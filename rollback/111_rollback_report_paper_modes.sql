-- Rollback for migration 111 - removes the report paper-mode columns.
-- Centres fall back to the old behaviour (full-page letterhead + margins).
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_PrescriptionProtocols_PaperMode')
    ALTER TABLE [dbo].[PrescriptionProtocols] DROP CONSTRAINT [CK_PrescriptionProtocols_PaperMode];
GO
DECLARE @c sysname;
DECLARE cols CURSOR LOCAL FAST_FORWARD FOR
    SELECT dc.name FROM sys.default_constraints dc
    JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID('dbo.PrescriptionProtocols')
      AND c.name IN ('PaperMode','ShowRegistration','ShowQr','PdfStandardHeader');
OPEN cols; FETCH NEXT FROM cols INTO @c;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC('ALTER TABLE [dbo].[PrescriptionProtocols] DROP CONSTRAINT [' + @c + ']');
    FETCH NEXT FROM cols INTO @c;
END
CLOSE cols; DEALLOCATE cols;
GO
IF COL_LENGTH('dbo.PrescriptionProtocols', 'PaperMode') IS NOT NULL          ALTER TABLE [dbo].[PrescriptionProtocols] DROP COLUMN [PaperMode];
IF COL_LENGTH('dbo.PrescriptionProtocols', 'HeaderImageBlobUrl') IS NOT NULL ALTER TABLE [dbo].[PrescriptionProtocols] DROP COLUMN [HeaderImageBlobUrl];
IF COL_LENGTH('dbo.PrescriptionProtocols', 'FooterImageBlobUrl') IS NOT NULL ALTER TABLE [dbo].[PrescriptionProtocols] DROP COLUMN [FooterImageBlobUrl];
IF COL_LENGTH('dbo.PrescriptionProtocols', 'LogoBlobUrl') IS NOT NULL        ALTER TABLE [dbo].[PrescriptionProtocols] DROP COLUMN [LogoBlobUrl];
IF COL_LENGTH('dbo.PrescriptionProtocols', 'AccentColor') IS NOT NULL        ALTER TABLE [dbo].[PrescriptionProtocols] DROP COLUMN [AccentColor];
IF COL_LENGTH('dbo.PrescriptionProtocols', 'ShowRegistration') IS NOT NULL   ALTER TABLE [dbo].[PrescriptionProtocols] DROP COLUMN [ShowRegistration];
IF COL_LENGTH('dbo.PrescriptionProtocols', 'ShowQr') IS NOT NULL             ALTER TABLE [dbo].[PrescriptionProtocols] DROP COLUMN [ShowQr];
IF COL_LENGTH('dbo.PrescriptionProtocols', 'PdfStandardHeader') IS NOT NULL  ALTER TABLE [dbo].[PrescriptionProtocols] DROP COLUMN [PdfStandardHeader];
GO
PRINT 'Migration 111 rolled back.';
GO
