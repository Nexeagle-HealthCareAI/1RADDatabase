SET QUOTED_IDENTIFIER ON;
GO
IF COL_LENGTH('dbo.ReferralCommissions', 'PayoutId') IS NOT NULL ALTER TABLE [dbo].[ReferralCommissions] DROP COLUMN [PayoutId];
GO
IF OBJECT_ID('dbo.ReferralPayouts', 'U') IS NOT NULL DROP TABLE [dbo].[ReferralPayouts];
GO
IF COL_LENGTH('dbo.Referrers', 'Pan') IS NOT NULL ALTER TABLE [dbo].[Referrers] DROP COLUMN [Pan];
GO
