-- Migration: 37_add_missing_subscription_columns.sql
-- Description: Adds missing properties to HospitalSubscriptions table that exist in the C# domain model.

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[HospitalSubscriptions]') AND name = 'BillingCycle'
)
BEGIN
    ALTER TABLE [dbo].[HospitalSubscriptions] ADD [BillingCycle] NVARCHAR(MAX) NULL;
    EXEC('UPDATE [dbo].[HospitalSubscriptions] SET [BillingCycle] = ''Trial'' WHERE [BillingCycle] IS NULL;');
    ALTER TABLE [dbo].[HospitalSubscriptions] ALTER COLUMN [BillingCycle] NVARCHAR(MAX) NOT NULL;
    PRINT 'Column dbo.HospitalSubscriptions.BillingCycle added successfully.';
END
ELSE
BEGIN
    PRINT 'Column dbo.HospitalSubscriptions.BillingCycle already exists — skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[HospitalSubscriptions]') AND name = 'IsLocked'
)
BEGIN
    ALTER TABLE [dbo].[HospitalSubscriptions] ADD [IsLocked] BIT NULL;
    EXEC('UPDATE [dbo].[HospitalSubscriptions] SET [IsLocked] = 0 WHERE [IsLocked] IS NULL;');
    ALTER TABLE [dbo].[HospitalSubscriptions] ALTER COLUMN [IsLocked] BIT NOT NULL;
    PRINT 'Column dbo.HospitalSubscriptions.IsLocked added successfully.';
END
ELSE
BEGIN
    PRINT 'Column dbo.HospitalSubscriptions.IsLocked already exists — skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[HospitalSubscriptions]') AND name = 'LockedAt'
)
BEGIN
    ALTER TABLE [dbo].[HospitalSubscriptions] ADD [LockedAt] DATETIME2 NULL;
    PRINT 'Column dbo.HospitalSubscriptions.LockedAt added successfully.';
END
ELSE
BEGIN
    PRINT 'Column dbo.HospitalSubscriptions.LockedAt already exists — skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[HospitalSubscriptions]') AND name = 'LockReason'
)
BEGIN
    ALTER TABLE [dbo].[HospitalSubscriptions] ADD [LockReason] NVARCHAR(MAX) NULL;
    PRINT 'Column dbo.HospitalSubscriptions.LockReason added successfully.';
END
ELSE
BEGIN
    PRINT 'Column dbo.HospitalSubscriptions.LockReason already exists — skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[HospitalSubscriptions]') AND name = 'NotificationSentAt'
)
BEGIN
    ALTER TABLE [dbo].[HospitalSubscriptions] ADD [NotificationSentAt] DATETIME2 NULL;
    PRINT 'Column dbo.HospitalSubscriptions.NotificationSentAt added successfully.';
END
ELSE
BEGIN
    PRINT 'Column dbo.HospitalSubscriptions.NotificationSentAt already exists — skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[HospitalSubscriptions]') AND name = 'ActivatedByUserId'
)
BEGIN
    ALTER TABLE [dbo].[HospitalSubscriptions] ADD [ActivatedByUserId] UNIQUEIDENTIFIER NULL;
    PRINT 'Column dbo.HospitalSubscriptions.ActivatedByUserId added successfully.';
END
ELSE
BEGIN
    PRINT 'Column dbo.HospitalSubscriptions.ActivatedByUserId already exists — skipped.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[HospitalSubscriptions]') AND name = 'ActivatedAt'
)
BEGIN
    ALTER TABLE [dbo].[HospitalSubscriptions] ADD [ActivatedAt] DATETIME2 NULL;
    PRINT 'Column dbo.HospitalSubscriptions.ActivatedAt added successfully.';
END
ELSE
BEGIN
    PRINT 'Column dbo.HospitalSubscriptions.ActivatedAt already exists — skipped.';
END
GO
