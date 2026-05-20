-- 1Rad Hub: Dynamic Custom Roles & Allowed Route Permissions Schema
-- Scopes custom roles by hospital facility context with unique naming.

BEGIN TRY
    BEGIN TRANSACTION;

    /* 1. CustomRoles Table (Hospital-scoped custom roles) */
    IF OBJECT_ID('dbo.CustomRoles', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.CustomRoles
        (
            CustomRoleId UNIQUEIDENTIFIER NOT NULL
                CONSTRAINT PK_CustomRoles PRIMARY KEY
                CONSTRAINT DF_CustomRoles_CustomRoleId DEFAULT NEWID(),
            
            HospitalId UNIQUEIDENTIFIER NOT NULL,
            RoleName NVARCHAR(100) NOT NULL,
            [Description] NVARCHAR(MAX) NULL,
            CreatedAt DATETIME2 NOT NULL
                CONSTRAINT DF_CustomRoles_CreatedAt DEFAULT GETUTCDATE(),

            CONSTRAINT FK_CustomRoles_Hospitals
                FOREIGN KEY (HospitalId)
                REFERENCES dbo.Hospitals(HospitalId)
                ON DELETE CASCADE,

            -- Ensure role names are unique within a single hospital/facility context
            CONSTRAINT UQ_CustomRoles_Hospital_RoleName UNIQUE (HospitalId, RoleName)
        );

        -- Performance index for context resolution
        CREATE NONCLUSTERED INDEX IX_CustomRoles_HospitalId ON dbo.CustomRoles(HospitalId);
        PRINT 'Created table [dbo].[CustomRoles].';
    END

    /* 2. CustomRolePermissions Table (Relational list of allowed navigation routes) */
    IF OBJECT_ID('dbo.CustomRolePermissions', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.CustomRolePermissions
        (
            CustomRoleId UNIQUEIDENTIFIER NOT NULL,
            RoutePath NVARCHAR(255) NOT NULL,

            CONSTRAINT PK_CustomRolePermissions PRIMARY KEY CLUSTERED (CustomRoleId, RoutePath),

            CONSTRAINT FK_CustomRolePermissions_CustomRoles
                FOREIGN KEY (CustomRoleId)
                REFERENCES dbo.CustomRoles(CustomRoleId)
                ON DELETE CASCADE
        );
        PRINT 'Created table [dbo].[CustomRolePermissions].';
    END

    /* 3. UserHospitalCustomRoles Table (Bridge linking custom roles to user hospital mappings) */
    IF OBJECT_ID('dbo.UserHospitalCustomRoles', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.UserHospitalCustomRoles
        (
            MappingId UNIQUEIDENTIFIER NOT NULL,
            CustomRoleId UNIQUEIDENTIFIER NOT NULL,
            AssignedAt DATETIME2 NOT NULL
                CONSTRAINT DF_UserHospitalCustomRoles_AssignedAt DEFAULT GETUTCDATE(),

            CONSTRAINT PK_UserHospitalCustomRoles PRIMARY KEY CLUSTERED (MappingId, CustomRoleId),

            CONSTRAINT FK_UserHospitalCustomRoles_UserHospitalMappings
                FOREIGN KEY (MappingId)
                REFERENCES dbo.UserHospitalMappings(MappingId)
                ON DELETE CASCADE,

            CONSTRAINT FK_UserHospitalCustomRoles_CustomRoles
                FOREIGN KEY (CustomRoleId)
                REFERENCES dbo.CustomRoles(CustomRoleId)
                ON DELETE CASCADE
        );
        PRINT 'Created table [dbo].[UserHospitalCustomRoles].';
    END

    COMMIT TRANSACTION;
    PRINT 'Custom roles DB schema provisioned successfully.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
        
    THROW;
END CATCH;
GO
