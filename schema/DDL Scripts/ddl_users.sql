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

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'Specialization')
BEGIN
    ALTER TABLE [dbo].[Users] 
    ADD [Specialization] NVARCHAR(500) NULL,
        [Degree] NVARCHAR(255) NULL,
        [LicenseNo] NVARCHAR(100) NULL;
END
GO
