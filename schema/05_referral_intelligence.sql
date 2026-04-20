-- 1Rad Database Migration: Referral Intelligence Update
-- Author: 1Rad Tactical AI
-- Timestamp: 2024-04-20

BEGIN TRANSACTION;

-- 1. Add ReferrerId to Patients table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Patients]') AND name = 'ReferrerId')
BEGIN
    ALTER TABLE [dbo].[Patients]
    ADD [ReferrerId] UNIQUEIDENTIFIER NULL;
END

-- 2. Add Foreign Key between Patients and Referrers
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Patients_Referrers_ReferrerId')
BEGIN
    ALTER TABLE [dbo].[Patients]
    WITH CHECK ADD CONSTRAINT [FK_Patients_Referrers_ReferrerId] 
    FOREIGN KEY ([ReferrerId]) REFERENCES [dbo].[Referrers]([ReferrerId])
    ON DELETE SET NULL;
END

-- 3. Create Index for Referral Analytics
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Patients_ReferrerId' AND object_id = OBJECT_ID(N'[dbo].[Patients]'))
BEGIN
    CREATE INDEX [IX_Patients_ReferrerId] ON [dbo].[Patients] ([ReferrerId]);
END

COMMIT;
