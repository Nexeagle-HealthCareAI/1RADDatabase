-- =============================================
-- Author:      Antigravity (AI Assistant)
-- Create Date: 2026-05-15
-- Description: Adds a persistent Password column to the Users table 
--              to store plain-text passwords for administrative visibility.
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'Password')
BEGIN
    PRINT 'ACTION: Adding [Password] column to [dbo].[Users]';
    
    ALTER TABLE [dbo].[Users] 
    ADD [Password] NVARCHAR(MAX) NOT NULL DEFAULT '';
    
    PRINT 'SUCCESS: [Password] column added to [dbo].[Users]';
END
ELSE
BEGIN
    PRINT 'NOTICE: [Password] column already exists in [dbo].[Users]';
END
GO
