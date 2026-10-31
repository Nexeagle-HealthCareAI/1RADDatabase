-- ============================================================
-- Migration 109 - HospitalBillingSettings: the centre admin's tax and billing switches
-- One optional row per centre. No row = defaults (GST on, credit notes on, TDS on at
-- the server's rates, front desk limited to the server's discount %). A NULL rate,
-- threshold or limit also means "use the default".
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF OBJECT_ID('dbo.HospitalBillingSettings', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[HospitalBillingSettings] (
        [HospitalId]                    UNIQUEIDENTIFIER NOT NULL,
        [GstEnabled]                    BIT              NOT NULL CONSTRAINT [DF_HospitalBillingSettings_Gst] DEFAULT (1),
        [CreditNotesEnabled]            BIT              NOT NULL CONSTRAINT [DF_HospitalBillingSettings_CN] DEFAULT (1),
        [TdsEnabled]                    BIT              NOT NULL CONSTRAINT [DF_HospitalBillingSettings_Tds] DEFAULT (1),
        [DefaultTdsCategory]            NVARCHAR(20)     NOT NULL CONSTRAINT [DF_HospitalBillingSettings_TdsCat] DEFAULT ('COMMISSION'),
        [TdsCommissionRate]             DECIMAL(5,2)     NULL,
        [TdsCommissionThreshold]        DECIMAL(18,2)    NULL,
        [TdsProfessionalRate]           DECIMAL(5,2)     NULL,
        [TdsProfessionalThreshold]      DECIMAL(18,2)    NULL,
        [TdsNoPanRate]                  DECIMAL(5,2)     NULL,
        [FrontDeskDiscountLimitPercent] DECIMAL(5,2)     NULL,
        [UpdatedByUserId]               UNIQUEIDENTIFIER NULL,
        [UpdatedAt]                     DATETIME2        NOT NULL,
        CONSTRAINT [PK_HospitalBillingSettings] PRIMARY KEY CLUSTERED ([HospitalId]),
        CONSTRAINT [FK_HospitalBillingSettings_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId]),
        CONSTRAINT [CK_HospitalBillingSettings_TdsCat] CHECK ([DefaultTdsCategory] IN ('COMMISSION', 'PROFESSIONAL', 'NONE')),
        CONSTRAINT [CK_HospitalBillingSettings_Rates] CHECK (
            ([TdsCommissionRate] IS NULL OR [TdsCommissionRate] BETWEEN 0 AND 50) AND
            ([TdsProfessionalRate] IS NULL OR [TdsProfessionalRate] BETWEEN 0 AND 50) AND
            ([TdsNoPanRate] IS NULL OR [TdsNoPanRate] BETWEEN 0 AND 50) AND
            ([FrontDeskDiscountLimitPercent] IS NULL OR [FrontDeskDiscountLimitPercent] BETWEEN 0 AND 100) AND
            ([TdsCommissionThreshold] IS NULL OR [TdsCommissionThreshold] >= 0) AND
            ([TdsProfessionalThreshold] IS NULL OR [TdsProfessionalThreshold] >= 0))
    );
END
GO
PRINT 'Migration 109 applied: HospitalBillingSettings.';
GO
