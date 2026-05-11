/* =========================================================
   1Rad / Clinical Command Hub
   Subscription Protocol Schema Evolution
   SQL Server / T-SQL
   ========================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   1. SubscriptionPlans
   ========================================================= */
IF OBJECT_ID('dbo.SubscriptionPlans', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SubscriptionPlans
    (
        PlanId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_SubscriptionPlans PRIMARY KEY
            CONSTRAINT DF_SubscriptionPlans_PlanId DEFAULT NEWID(),

        Name NVARCHAR(50) NOT NULL,
        Price DECIMAL(18, 2) NOT NULL,
        DurationInDays INT NOT NULL,
        DiscountPercentage DECIMAL(18, 2) NOT NULL,
        PerAdditionalDoctorPrice DECIMAL(18, 2) NOT NULL 
            CONSTRAINT DF_SubscriptionPlans_PerAdditionalDoctorPrice DEFAULT 1000,
        IsActive BIT NOT NULL 
            CONSTRAINT DF_SubscriptionPlans_IsActive DEFAULT 1,

        CreatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_SubscriptionPlans_CreatedAt DEFAULT GETUTCDATE()
    );
END
GO

/* =========================================================
   2. HospitalSubscriptions
   ========================================================= */
IF OBJECT_ID('dbo.HospitalSubscriptions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.HospitalSubscriptions
    (
        SubscriptionId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_HospitalSubscriptions PRIMARY KEY
            CONSTRAINT DF_HospitalSubscriptions_SubscriptionId DEFAULT NEWID(),

        HospitalId UNIQUEIDENTIFIER NOT NULL,
        PlanId UNIQUEIDENTIFIER NULL,
        
        StartDate DATETIME2 NOT NULL,
        EndDate DATETIME2 NOT NULL,
        IsTrial BIT NOT NULL
            CONSTRAINT DF_HospitalSubscriptions_IsTrial DEFAULT 0,
        [Status] NVARCHAR(50) NOT NULL
            CONSTRAINT DF_HospitalSubscriptions_Status DEFAULT 'Active',

        CreatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_HospitalSubscriptions_CreatedAt DEFAULT GETUTCDATE(),

        CONSTRAINT FK_HospitalSubscriptions_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId),

        CONSTRAINT FK_HospitalSubscriptions_Plans
            FOREIGN KEY (PlanId)
            REFERENCES dbo.SubscriptionPlans(PlanId)
    );
END
GO

/* =========================================================
   3. Seed Initial Plans
   ========================================================= */
MERGE INTO dbo.SubscriptionPlans AS Target
USING (VALUES 
    ('A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D', 'Monthly', 4999.00, 30, 0.00, 1000.00),
    ('B2C3D4E5-F6A7-4B6C-9D0E-1F2A3B4C5D6E', 'Yearly', 59988.00, 365, 10.00, 10800.00)
) AS Source (PlanId, Name, Price, DurationInDays, DiscountPercentage, PerAdditionalDoctorPrice)
ON Target.PlanId = Source.PlanId
WHEN NOT MATCHED BY TARGET THEN
    INSERT (PlanId, Name, Price, DurationInDays, DiscountPercentage, PerAdditionalDoctorPrice)
    VALUES (Source.PlanId, Source.Name, Source.Price, Source.DurationInDays, Source.DiscountPercentage, Source.PerAdditionalDoctorPrice);
GO
