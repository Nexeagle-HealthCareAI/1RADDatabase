-- ============================================================
-- Migration 100 - RateLimitCounters: request limits shared by every API instance
-- (gap analysis P3-9)
--
-- The ASP.NET in-memory limiter counted per process, so N instances allowed N times
-- the limit — and the OTP limit was one global bucket (5 per 10 min for the whole
-- platform). The API now counts in this table: one row per (key, fixed window).
-- Rows older than a day are deleted opportunistically by the API.
-- ============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.RateLimitCounters', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[RateLimitCounters] (
        [LimitKey]    NVARCHAR(200) NOT NULL,   -- e.g. otp-send:919876543210
        [WindowStart] DATETIME2     NOT NULL,   -- UTC start of the fixed window
        [Hits]        INT           NOT NULL,
        CONSTRAINT [PK_RateLimitCounters] PRIMARY KEY CLUSTERED ([LimitKey], [WindowStart])
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RateLimitCounters_WindowStart' AND object_id = OBJECT_ID('dbo.RateLimitCounters'))
    CREATE INDEX [IX_RateLimitCounters_WindowStart] ON [dbo].[RateLimitCounters] ([WindowStart]);
GO
