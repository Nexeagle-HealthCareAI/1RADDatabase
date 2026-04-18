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


-- SQL Migration Script for Hospital Metadata Fields

-- Target Table: dbo.Hospitals
-- Schema: dbo

-- 1. Add RegistrationNumber
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Hospitals]') AND name = 'RegistrationNumber')
BEGIN
    ALTER TABLE [dbo].[Hospitals] ADD [RegistrationNumber] nvarchar(100) NULL;
END
GO

-- 2. Add PAN
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Hospitals]') AND name = 'PAN')
BEGIN
    ALTER TABLE [dbo].[Hospitals] ADD [PAN] nvarchar(10) NULL;
END
GO

-- 3. Add NABHNumber
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Hospitals]') AND name = 'NABHNumber')
BEGIN
    ALTER TABLE [dbo].[Hospitals] ADD [NABHNumber] nvarchar(100) NULL;
END
GO

-- 4. Update GSTIN Constraints (Optional - Ensure MaxLength 15)
-- Note: This depends on existing column state.
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Hospitals]') AND name = 'GSTIN')
BEGIN
    ALTER TABLE [dbo].[Hospitals] ALTER COLUMN [GSTIN] nvarchar(15) NULL;
END
GO




