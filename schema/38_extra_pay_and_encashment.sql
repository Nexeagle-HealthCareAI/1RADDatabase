-- =========================================================================================
-- MIGRATION: 38_extra_pay_and_encashment.sql
-- DESCRIPTION: Add Extra Pay and Leave Encashment columns to SalaryDisbursements table
-- =========================================================================================

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE Name = N'EncashmentBonus'
      AND Object_ID = Object_ID(N'dbo.SalaryDisbursements')
)
BEGIN
    ALTER TABLE [dbo].[SalaryDisbursements] ADD [EncashmentBonus] decimal(18,2) NOT NULL DEFAULT 0.0;
    PRINT 'Added EncashmentBonus column to SalaryDisbursements.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE Name = N'EncashmentDays'
      AND Object_ID = Object_ID(N'dbo.SalaryDisbursements')
)
BEGIN
    ALTER TABLE [dbo].[SalaryDisbursements] ADD [EncashmentDays] decimal(18,2) NOT NULL DEFAULT 0.0;
    PRINT 'Added EncashmentDays column to SalaryDisbursements.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE Name = N'ExtraPay'
      AND Object_ID = Object_ID(N'dbo.SalaryDisbursements')
)
BEGIN
    ALTER TABLE [dbo].[SalaryDisbursements] ADD [ExtraPay] decimal(18,2) NOT NULL DEFAULT 0.0;
    PRINT 'Added ExtraPay column to SalaryDisbursements.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE Name = N'ExtraPayReason'
      AND Object_ID = Object_ID(N'dbo.SalaryDisbursements')
)
BEGIN
    ALTER TABLE [dbo].[SalaryDisbursements] ADD [ExtraPayReason] nvarchar(max) NULL;
    PRINT 'Added ExtraPayReason column to SalaryDisbursements.';
END
GO

COMMIT TRANSACTION;
GO
