/* =========================================================
   1Rad / Clinical Command Hub
   Subscription Payment Requests Schema
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.SubscriptionPaymentRequests', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[SubscriptionPaymentRequests] (
        [RequestId] uniqueidentifier NOT NULL,
        [HospitalId] uniqueidentifier NOT NULL,
        [PlanName] nvarchar(50) NOT NULL,
        [BillingCycle] nvarchar(20) NOT NULL,
        [Amount] decimal(18,2) NOT NULL,
        [PayerName] nvarchar(255) NOT NULL,
        [PayerContact] nvarchar(100) NOT NULL,
        [TransactionReference] nvarchar(255) NOT NULL,
        [PaymentMode] nvarchar(50) NOT NULL,
        [PaidAt] datetime2 NOT NULL,
        [Status] nvarchar(20) NOT NULL DEFAULT N'Pending',
        [ReviewNote] nvarchar(500) NULL,
        [ReviewedByUserId] uniqueidentifier NULL,
        [ReviewedAt] datetime2 NULL,
        [PaymentGatewayOrderId] nvarchar(255) NULL,
        [PaymentGatewayResponse] nvarchar(2000) NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_SubscriptionPaymentRequests] PRIMARY KEY ([RequestId]),
        CONSTRAINT [FK_SubscriptionPaymentRequests_Hospitals_HospitalId] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId]) ON DELETE CASCADE
    );

    CREATE INDEX [IX_SubscriptionPaymentRequests_HospitalId_Status] ON [dbo].[SubscriptionPaymentRequests] ([HospitalId], [Status]);
END
GO
