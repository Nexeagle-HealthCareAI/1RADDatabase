/* =========================================================
   33 - Hospital Leave Policy

   One row per hospital. Stores the configured leave types and
   annual quotas as a JSON array. Schema of each entry:
   { "id": "sick", "name": "Sick Leave", "annualQuota": 6,
     "isPaid": true, "color": "#dc2626" }

   Configured from the Staff & Payroll > Leave Policy tab,
   applied to every employee when computing payroll LWP.
   ========================================================= */

IF OBJECT_ID('dbo.HospitalLeavePolicies', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.HospitalLeavePolicies
    (
        PolicyId UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_HospitalLeavePolicies PRIMARY KEY
            CONSTRAINT DF_HospitalLeavePolicies_PolicyId DEFAULT NEWID(),

        HospitalId UNIQUEIDENTIFIER NOT NULL,

        -- JSON array of leave type objects
        LeaveTypesJson NVARCHAR(4000) NOT NULL
            CONSTRAINT DF_HospitalLeavePolicies_LeaveTypesJson DEFAULT N'[]',

        UpdatedAt       DATETIME2 NOT NULL
            CONSTRAINT DF_HospitalLeavePolicies_UpdatedAt DEFAULT GETUTCDATE(),
        UpdatedByUserId UNIQUEIDENTIFIER NULL,

        CONSTRAINT FK_HospitalLeavePolicies_Hospitals
            FOREIGN KEY (HospitalId)
            REFERENCES dbo.Hospitals(HospitalId)
            ON DELETE CASCADE
    );
    PRINT 'Created table dbo.HospitalLeavePolicies';
END
ELSE
    PRINT 'Table dbo.HospitalLeavePolicies already exists — skipped.';
GO

-- One policy per hospital
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'UX_HospitalLeavePolicies_HospitalId'
               AND object_id = OBJECT_ID('dbo.HospitalLeavePolicies'))
    CREATE UNIQUE INDEX UX_HospitalLeavePolicies_HospitalId
        ON dbo.HospitalLeavePolicies (HospitalId);
GO
