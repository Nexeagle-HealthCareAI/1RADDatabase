-- Rollback for schema/97_audit_logs.sql — deletes the audit history. Only with an API
-- version that no longer maps AuditLog.
IF OBJECT_ID('dbo.AuditLogs', 'U') IS NOT NULL DROP TABLE [dbo].[AuditLogs];
GO
