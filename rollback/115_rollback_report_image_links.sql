-- Rollback for 115_report_image_links.sql. Roll the API back FIRST.
-- Drops key-image links, AI drafts and the kept de-identified cases.
SET NOCOUNT ON;
IF OBJECT_ID('dbo.ApprovedReportCases', 'U') IS NOT NULL DROP TABLE dbo.ApprovedReportCases;
IF OBJECT_ID('dbo.ReportAiDrafts', 'U') IS NOT NULL DROP TABLE dbo.ReportAiDrafts;
IF OBJECT_ID('dbo.ReportKeyImages', 'U') IS NOT NULL DROP TABLE dbo.ReportKeyImages;
IF COL_LENGTH('dbo.CentreAiPolicies', 'CaptureApprovedCases') IS NOT NULL
BEGIN
    ALTER TABLE dbo.CentreAiPolicies DROP CONSTRAINT DF_CentreAiPolicies_Capture;
    ALTER TABLE dbo.CentreAiPolicies DROP COLUMN CaptureApprovedCases;
END
IF COL_LENGTH('dbo.CentreAiPolicies', 'VisionDraftEnabled') IS NOT NULL
BEGIN
    ALTER TABLE dbo.CentreAiPolicies DROP CONSTRAINT DF_CentreAiPolicies_VisionDraft;
    ALTER TABLE dbo.CentreAiPolicies DROP COLUMN VisionDraftEnabled;
END
PRINT 'Rolled back 115';
