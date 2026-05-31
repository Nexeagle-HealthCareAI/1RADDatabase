-- Migration: 50_idempotency_keys.sql
-- Description: Phase B2 Track 2 — server-side idempotency dedupe for
--              the offline outbox. The frontend already sends an
--              Idempotency-Key header on every queued mutation push;
--              this table is what makes a retried push a true no-op
--              instead of producing a duplicate row.
--
--              The middleware (IdempotencyMiddleware) writes one record
--              per successful mutating request and replays the stored
--              response on a retry that arrives within the TTL window.
--
-- TTL: 24 hours. Industry default, covers "left the laptop in the car
-- overnight" scenarios without growing the table indefinitely. A
-- background sweep deletes expired records — for now the middleware
-- opportunistically deletes on lookup hit; a SQL Agent job can be added
-- later if the table ever grows large.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.tables
    WHERE name = 'IdempotencyKeys' AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    CREATE TABLE [dbo].[IdempotencyKeys] (
        -- Composite (UserId, Key) so two users can't collide on the
        -- same client-generated UUID. UserId is optional (some calls
        -- are AllowAnonymous — those get a NULL UserId and the key
        -- alone disambiguates).
        [Key]              NVARCHAR(80)   NOT NULL,
        [UserId]           UNIQUEIDENTIFIER NULL,
        -- Request fingerprint. We compare on retry so a key reused
        -- against a DIFFERENT endpoint (developer error) doesn't
        -- accidentally replay the wrong response.
        [Method]           NVARCHAR(10)   NOT NULL,
        [Path]             NVARCHAR(500)  NOT NULL,
        -- Captured response. Only success codes (200-299) are cached;
        -- failures are not idempotent so we re-execute on retry.
        [ResponseStatus]   INT            NOT NULL,
        [ResponseBody]     NVARCHAR(MAX)  NULL,
        [ResponseContentType] NVARCHAR(120) NULL,
        [CreatedAt]        DATETIME2      NOT NULL CONSTRAINT [DF_IdempotencyKeys_CreatedAt] DEFAULT SYSUTCDATETIME(),
        [ExpiresAt]        DATETIME2      NOT NULL,
        CONSTRAINT [PK_IdempotencyKeys] PRIMARY KEY CLUSTERED ([Key], [UserId])
    );
    PRINT 'Table dbo.IdempotencyKeys created.';
END
ELSE PRINT 'Table dbo.IdempotencyKeys already exists - skipped.';
GO

-- Sweep index. The opportunistic cleanup in the middleware can use this
-- to delete expired rows in batches without scanning the heap.
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_IdempotencyKeys_ExpiresAt'
      AND object_id = OBJECT_ID(N'[dbo].[IdempotencyKeys]')
)
BEGIN
    CREATE INDEX [IX_IdempotencyKeys_ExpiresAt]
        ON [dbo].[IdempotencyKeys] ([ExpiresAt]);
    PRINT 'Index IX_IdempotencyKeys_ExpiresAt created.';
END
ELSE PRINT 'Index IX_IdempotencyKeys_ExpiresAt already exists - skipped.';
GO
