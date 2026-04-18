IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[Users]') 
    AND name = 'Status'
)
BEGIN
    ALTER TABLE [dbo].[Users] 
    ADD [Status] NVARCHAR(50) NOT NULL DEFAULT 'Pending';
END
GO
