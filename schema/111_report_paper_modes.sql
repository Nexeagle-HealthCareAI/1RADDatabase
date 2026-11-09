-- ============================================================
-- Migration 111 - Report paper: three ways to print a report
--
-- PrescriptionProtocols (one row per centre, see migration 79) gains a
-- PaperMode and the few settings each mode needs:
--
--   IMAGES     - centre uploads a header picture and a footer picture;
--                the report text is written in between.
--   STANDARD   - our built-in design, drawn from the centre's details
--                (name, address, registration) plus a logo and a colour.
--   LETTERHEAD - the centre prints on its own pre-printed paper; we print
--                only the text, keeping HeaderMargin / BottomMargin empty.
--                A full-page letterhead image (LetterheadBlobUrl, the old
--                behaviour) also lives in this mode.
--
-- Existing centres keep exactly what they print today: a centre with a
-- letterhead image (or only margins) becomes LETTERHEAD; a centre that
-- never set anything up has no row and gets STANDARD from the API default.
--
-- Idempotent - safe to re-run.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('dbo.PrescriptionProtocols', 'PaperMode') IS NULL
BEGIN
    ALTER TABLE [dbo].[PrescriptionProtocols]
        ADD [PaperMode] NVARCHAR(20) NOT NULL
            CONSTRAINT [DF_PrescriptionProtocols_PaperMode] DEFAULT (N'LETTERHEAD');
    PRINT '  + PaperMode';
END
GO
IF COL_LENGTH('dbo.PrescriptionProtocols', 'HeaderImageBlobUrl') IS NULL
    ALTER TABLE [dbo].[PrescriptionProtocols] ADD [HeaderImageBlobUrl] NVARCHAR(500) NULL;
GO
IF COL_LENGTH('dbo.PrescriptionProtocols', 'FooterImageBlobUrl') IS NULL
    ALTER TABLE [dbo].[PrescriptionProtocols] ADD [FooterImageBlobUrl] NVARCHAR(500) NULL;
GO
IF COL_LENGTH('dbo.PrescriptionProtocols', 'LogoBlobUrl') IS NULL
    ALTER TABLE [dbo].[PrescriptionProtocols] ADD [LogoBlobUrl] NVARCHAR(500) NULL;
GO
IF COL_LENGTH('dbo.PrescriptionProtocols', 'AccentColor') IS NULL
    ALTER TABLE [dbo].[PrescriptionProtocols] ADD [AccentColor] NVARCHAR(20) NULL;
GO
IF COL_LENGTH('dbo.PrescriptionProtocols', 'ShowRegistration') IS NULL
    ALTER TABLE [dbo].[PrescriptionProtocols] ADD [ShowRegistration] BIT NOT NULL
        CONSTRAINT [DF_PrescriptionProtocols_ShowRegistration] DEFAULT (1);
GO
IF COL_LENGTH('dbo.PrescriptionProtocols', 'ShowQr') IS NULL
    ALTER TABLE [dbo].[PrescriptionProtocols] ADD [ShowQr] BIT NOT NULL
        CONSTRAINT [DF_PrescriptionProtocols_ShowQr] DEFAULT (1);
GO
-- LETTERHEAD mode only: add the standard header to PDF / WhatsApp copies
-- (a PDF has no pre-printed paper, so it would otherwise look bare).
IF COL_LENGTH('dbo.PrescriptionProtocols', 'PdfStandardHeader') IS NULL
    ALTER TABLE [dbo].[PrescriptionProtocols] ADD [PdfStandardHeader] BIT NOT NULL
        CONSTRAINT [DF_PrescriptionProtocols_PdfStandardHeader] DEFAULT (1);
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_PrescriptionProtocols_PaperMode')
    ALTER TABLE [dbo].[PrescriptionProtocols] WITH CHECK
        ADD CONSTRAINT [CK_PrescriptionProtocols_PaperMode]
        CHECK ([PaperMode] IN (N'IMAGES', N'STANDARD', N'LETTERHEAD'));
GO

PRINT 'Migration 111 applied: PrescriptionProtocols paper modes.';
GO
