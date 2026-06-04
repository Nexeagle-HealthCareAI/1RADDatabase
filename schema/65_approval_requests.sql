-- ════════════════════════════════════════════════════════════════════════════
--  65_approval_requests.sql
--
--  Admin sign-off queue. Sensitive changes after payment — editing a recorded
--  payment, cancelling a PAID appointment, or changing the referrer on a PAID
--  invoice — are submitted here as PENDING requests with a reason. An admin /
--  admin-doctor reviews them on Finance → Approvals and APPROVES (the change is
--  applied) or REJECTS. Idempotent: safe to re-run.
-- ════════════════════════════════════════════════════════════════════════════

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ApprovalRequests' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[ApprovalRequests] (
        [Id]            UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ApprovalRequests_Id] DEFAULT NEWID(),
        [HospitalId]    UNIQUEIDENTIFIER NOT NULL,
        [Type]          NVARCHAR(40)     NOT NULL,   -- EDIT_PAYMENT | CANCEL_APPOINTMENT | CHANGE_REFERRER
        [Title]         NVARCHAR(200)    NOT NULL CONSTRAINT [DF_ApprovalRequests_Title] DEFAULT (''),
        [InvoiceId]     UNIQUEIDENTIFIER NULL,
        [AppointmentId] UNIQUEIDENTIFIER NULL,
        [Payload]       NVARCHAR(MAX)    NOT NULL CONSTRAINT [DF_ApprovalRequests_Payload] DEFAULT ('{}'),
        [Reason]        NVARCHAR(MAX)    NOT NULL CONSTRAINT [DF_ApprovalRequests_Reason] DEFAULT (''),
        [Status]        NVARCHAR(20)     NOT NULL CONSTRAINT [DF_ApprovalRequests_Status] DEFAULT ('PENDING'),
        [RequestedBy]   UNIQUEIDENTIFIER NOT NULL,
        [ReviewedBy]    UNIQUEIDENTIFIER NULL,
        [ReviewNote]    NVARCHAR(MAX)    NULL,
        [ReviewedAt]    DATETIME2        NULL,
        [CreatedAt]     DATETIME2        NOT NULL CONSTRAINT [DF_ApprovalRequests_CreatedAt] DEFAULT (SYSUTCDATETIME()),
        [UpdatedAt]     DATETIME2        NOT NULL CONSTRAINT [DF_ApprovalRequests_UpdatedAt] DEFAULT (SYSUTCDATETIME()),
        [DeletedAt]     DATETIME2        NULL,
        CONSTRAINT [PK_ApprovalRequests] PRIMARY KEY CLUSTERED ([Id])
    );

    -- The Approvals page lists this hospital's PENDING requests, newest first.
    CREATE INDEX [IX_ApprovalRequests_Hospital_Status]
        ON [dbo].[ApprovalRequests] ([HospitalId], [Status], [CreatedAt] DESC);

    PRINT 'Table dbo.ApprovalRequests created.';
END
ELSE PRINT 'Table dbo.ApprovalRequests already exists - skipped.';
