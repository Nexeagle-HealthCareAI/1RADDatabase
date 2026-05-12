/* =========================================================
   1Rad / Finance Hub
   Migration: Referral Commission Appointment Link
   SQL Server / T-SQL
   ========================================================= */

BEGIN TRANSACTION;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ReferralCommissions]') AND name = 'AppointmentId')
BEGIN
    ALTER TABLE [dbo].[ReferralCommissions]
    ADD [AppointmentId] UNIQUEIDENTIFIER NULL;
END

COMMIT;
