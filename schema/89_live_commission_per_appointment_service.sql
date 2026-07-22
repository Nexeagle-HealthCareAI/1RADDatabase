-- One live referral commission is allowed per appointment service. Paid
-- history remains linked to its service; approved clawback rows are detached,
-- and soft-deleted rows remain auditable without blocking reconciliation.
SET NOCOUNT ON;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_ReferralCommissions_Live_AppointmentService'
      AND object_id = OBJECT_ID(N'[dbo].[ReferralCommissions]')
)
BEGIN
    IF EXISTS (
        SELECT [AppointmentServiceId]
        FROM [dbo].[ReferralCommissions]
        WHERE [AppointmentServiceId] IS NOT NULL
          AND [DeletedAt] IS NULL
        GROUP BY [AppointmentServiceId]
        HAVING COUNT(*) > 1
    )
    BEGIN
        PRINT 'Resolving duplicate live service commissions...';
        WITH RankedCommissions AS (
            SELECT 
                [Id],
                ROW_NUMBER() OVER(
                    PARTITION BY [AppointmentServiceId] 
                    ORDER BY [CreatedAt] DESC, [Id] DESC
                ) as rn
            FROM [dbo].[ReferralCommissions]
            WHERE [AppointmentServiceId] IS NOT NULL 
              AND [DeletedAt] IS NULL
        )
        UPDATE [dbo].[ReferralCommissions]
        SET [DeletedAt] = GETUTCDATE()
        WHERE [Id] IN (
            SELECT [Id] FROM RankedCommissions WHERE rn > 1
        );
        PRINT 'Duplicates resolved.';
    END;

    CREATE UNIQUE INDEX [UX_ReferralCommissions_Live_AppointmentService]
        ON [dbo].[ReferralCommissions] ([AppointmentServiceId])
        WHERE [AppointmentServiceId] IS NOT NULL AND [DeletedAt] IS NULL;

    PRINT 'Created UX_ReferralCommissions_Live_AppointmentService.';
END
ELSE
BEGIN
    PRINT 'UX_ReferralCommissions_Live_AppointmentService already exists.';
END;
GO