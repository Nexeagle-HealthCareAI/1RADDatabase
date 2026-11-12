-- Rollback for 120_owner_board_settings_links.sql. Roll the API back FIRST.
-- Centres keep their current settings and prices; they just stop following.
SET NOCOUNT ON;
IF OBJECT_ID('dbo.HospitalSettingsLinks', 'U') IS NOT NULL
    DROP TABLE dbo.HospitalSettingsLinks;
PRINT 'Rolled back 120';
