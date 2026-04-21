/* =========================================================
   1Rad / Clinical Command Hub
   Patch: 07_hospital_settings_patch.sql
   Description: Adds IsAutoBillingEnabled to dbo.Hospitals
   ========================================================= */

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID('dbo.Hospitals') 
               AND name = 'IsAutoBillingEnabled')
BEGIN
    PRINT 'Deploying IsAutoBillingEnabled to dbo.Hospitals...';
    
    ALTER TABLE dbo.Hospitals
    ADD IsAutoBillingEnabled BIT NOT NULL
    CONSTRAINT DF_Hospitals_IsAutoBillingEnabled DEFAULT 0;

    PRINT 'Deployment Successful.';
END
ELSE
BEGIN
    PRINT 'Schema already synchronized.';
END
GO
