-- ============================================================
-- Migration 104 - DayCloses: end-of-day cash count (review B12)
-- One row per centre per IST day: what the day book expected in each mode and
-- what the cashier counted in the drawer.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF OBJECT_ID('dbo.DayCloses', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DayCloses] (
        [Id]             UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_DayCloses_Id] DEFAULT (NEWID()),
        [HospitalId]     UNIQUEIDENTIFIER NOT NULL,
        [BusinessDate]   DATETIME2        NOT NULL,
        [ExpectedCash]   DECIMAL(18,2)    NOT NULL,
        [CountedCash]    DECIMAL(18,2)    NOT NULL,
        [Variance]       DECIMAL(18,2)    NOT NULL,
        [ExpectedUpi]    DECIMAL(18,2)    NOT NULL,
        [ExpectedCard]   DECIMAL(18,2)    NOT NULL,
        [ExpectedOther]  DECIMAL(18,2)    NOT NULL,
        [Note]           NVARCHAR(500)    NULL,
        [ClosedByUserId] UNIQUEIDENTIFIER NULL,
        [ClosedByName]   NVARCHAR(200)    NULL,
        [ClosedAt]       DATETIME2        NOT NULL,
        [CloseCount]     INT              NOT NULL CONSTRAINT [DF_DayCloses_CloseCount] DEFAULT (1),
        CONSTRAINT [PK_DayCloses] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_DayCloses_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId])
    );
    CREATE UNIQUE INDEX [IX_DayCloses_HospitalId_BusinessDate] ON [dbo].[DayCloses] ([HospitalId], [BusinessDate]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CreditTransactions_Hospital_CreatedAt' AND object_id = OBJECT_ID('dbo.CreditTransactions'))
    CREATE INDEX [IX_CreditTransactions_Hospital_CreatedAt] ON [dbo].[CreditTransactions] ([HospitalId], [CreatedAt]);
GO
PRINT 'Migration 104 applied: DayCloses.';
GO
