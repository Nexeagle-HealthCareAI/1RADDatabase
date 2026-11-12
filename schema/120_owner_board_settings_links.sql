-- ============================================================
-- 120 OWNER BOARD: CENTRES THAT FOLLOW ANOTHER CENTRE'S SETUP
-- Mirrors HospitalSettingsLink (ApplicationDbContext).
--
-- One row per centre that follows a main centre. While LinkBilling is 1, saving
-- the main centre's billing rules (discounts, partner payouts, GST, credit notes,
-- TDS) saves them here too; while LinkPrices is 1, each price saved at the main
-- centre is saved here too. A centre with no row has its own setup.
-- A new centre made with "start with the setup of …" gets a row by default.
-- Requires 109. Safe to run more than once.
-- Rollback: rollback/120_rollback_owner_board_settings_links.sql
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
SET NOCOUNT ON;
IF OBJECT_ID('dbo.HospitalSettingsLinks', 'U') IS NULL
    CREATE TABLE dbo.HospitalSettingsLinks (
        HospitalId       UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HospitalSettingsLinks PRIMARY KEY,
        SourceHospitalId UNIQUEIDENTIFIER NOT NULL,
        LinkBilling      BIT NOT NULL CONSTRAINT DF_HospitalSettingsLinks_LinkBilling DEFAULT 1,
        LinkPrices       BIT NOT NULL CONSTRAINT DF_HospitalSettingsLinks_LinkPrices DEFAULT 1,
        LinkedByUserId   UNIQUEIDENTIFIER NULL,
        LinkedAt         DATETIME2 NOT NULL CONSTRAINT DF_HospitalSettingsLinks_LinkedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_HospitalSettingsLinks_Hospital FOREIGN KEY (HospitalId) REFERENCES dbo.Hospitals (HospitalId),
        CONSTRAINT FK_HospitalSettingsLinks_Source FOREIGN KEY (SourceHospitalId) REFERENCES dbo.Hospitals (HospitalId),
        CONSTRAINT CK_HospitalSettingsLinks_NotSelf CHECK (HospitalId <> SourceHospitalId)
    );
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_HospitalSettingsLinks_Source' AND object_id = OBJECT_ID('dbo.HospitalSettingsLinks'))
    CREATE INDEX IX_HospitalSettingsLinks_Source ON dbo.HospitalSettingsLinks (SourceHospitalId);
PRINT 'Migration 120 applied: centres can follow a main centre''s setup.';
