-- ════════════════════════════════════════════════════════════════════════════
--  81_patient_credit_wallet.sql
--
--  Patient credit wallet (advance payments / overpayments / refunds). Until now
--  a payment could never exceed the invoice balance (CollectPayment rejected it),
--  so an advance "pay more now, return later" had nowhere to live. This ledger
--  records every wallet movement; the patient's balance is the running sum:
--      + ADVANCE   (overpayment parked at collection)
--      − APPLIED   (credit used against a later invoice)
--      − REFUND    (cash returned to the patient)
--
--  Hospital-scoped (HospitalId), patient-keyed (PatientId). InvoiceId is the
--  source invoice for ADVANCE, the target invoice for APPLIED, NULL for a cash
--  REFUND. Run against your 1RadDb database. Idempotent — safe to re-run.
-- ════════════════════════════════════════════════════════════════════════════

SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CreditTransactions')
BEGIN
    CREATE TABLE dbo.CreditTransactions
    (
        [Id]               UNIQUEIDENTIFIER NOT NULL CONSTRAINT [PK_CreditTransactions] PRIMARY KEY,
        [HospitalId]       UNIQUEIDENTIFIER NOT NULL,
        [PatientId]        UNIQUEIDENTIFIER NOT NULL,
        [PatientName]      NVARCHAR(255)    NULL,
        [Type]             NVARCHAR(20)     NOT NULL,   -- ADVANCE | APPLIED | REFUND
        [Amount]           DECIMAL(18,2)    NOT NULL,   -- always positive; sign implied by Type
        [InvoiceId]        UNIQUEIDENTIFIER NULL,
        [InvoiceDisplayId] NVARCHAR(50)     NULL,
        [PaymentMethod]    NVARCHAR(50)     NULL,
        [Remarks]          NVARCHAR(500)    NULL,
        [CreatedByUserId]  UNIQUEIDENTIFIER NULL,
        [CreatedAt]        DATETIME2        NOT NULL CONSTRAINT [DF_CreditTransactions_CreatedAt] DEFAULT (SYSUTCDATETIME()),
        [UpdatedAt]        DATETIME2        NOT NULL CONSTRAINT [DF_CreditTransactions_UpdatedAt] DEFAULT (SYSUTCDATETIME()),
        [DeletedAt]        DATETIME2        NULL
    );
    PRINT '  + Created dbo.CreditTransactions';

    CREATE INDEX [IX_CreditTransactions_Hospital_Patient]
        ON dbo.CreditTransactions ([HospitalId], [PatientId]);
    CREATE INDEX [IX_CreditTransactions_Hospital_UpdatedAt]
        ON dbo.CreditTransactions ([HospitalId], [UpdatedAt]);
    PRINT '  + Created indexes on dbo.CreditTransactions';
END
ELSE PRINT '  = dbo.CreditTransactions already exists.';
GO
