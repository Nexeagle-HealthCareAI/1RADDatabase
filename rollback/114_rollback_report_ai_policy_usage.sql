-- Rollback for 114_report_ai_policy_usage.sql. Drops the AI usage history
-- and every centre's AI rules. Roll the API back FIRST — the current API reads
-- these tables on every report-AI request.
SET NOCOUNT ON;
IF OBJECT_ID('dbo.ReportAiUsageLogs', 'U') IS NOT NULL DROP TABLE dbo.ReportAiUsageLogs;
IF OBJECT_ID('dbo.CentreAiPolicies', 'U') IS NOT NULL DROP TABLE dbo.CentreAiPolicies;
PRINT 'Rolled back 114';
