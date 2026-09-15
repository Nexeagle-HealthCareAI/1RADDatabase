-- Keep patient credit wallets non-negative under concurrent apply/refund writes.
-- The ledger remains the source of truth; this trigger serializes balance checks
-- for only the affected (HospitalId, PatientId) scopes.
SET NOCOUNT ON;
GO

CREATE OR ALTER TRIGGER [dbo].[TR_CreditTransactions_EnsureNonNegativeBalance]
ON [dbo].[CreditTransactions]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @affected TABLE
    (
        HospitalId UNIQUEIDENTIFIER NOT NULL,
        PatientId UNIQUEIDENTIFIER NOT NULL,
        PRIMARY KEY (HospitalId, PatientId)
    );

    INSERT INTO @affected (HospitalId, PatientId)
    SELECT HospitalId, PatientId FROM inserted
    UNION
    SELECT HospitalId, PatientId FROM deleted;

    IF EXISTS
    (
        SELECT 1
        FROM @affected AS affected
        CROSS APPLY
        (
            SELECT SUM(CASE WHEN [Type] = 'ADVANCE' THEN Amount ELSE -Amount END) AS Balance
            FROM [dbo].[CreditTransactions] WITH (UPDLOCK, HOLDLOCK, INDEX([IX_CreditTransactions_Hospital_Patient]))
            WHERE HospitalId = affected.HospitalId
              AND PatientId = affected.PatientId
              AND DeletedAt IS NULL
        ) AS wallet
        WHERE COALESCE(wallet.Balance, 0) < -0.01
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51001, 'Credit wallet balance cannot become negative.', 1;
    END;
END;
GO
