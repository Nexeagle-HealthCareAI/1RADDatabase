-- Rollback for 121_work_calendar_leave_ledger.sql. Roll the API back FIRST.
-- Removes the centre calendars, holiday lists, personal weekly offs and the
-- leave ledger (opening balances, corrections, carry-forwards). Leave requests stay.
SET NOCOUNT ON;
IF OBJECT_ID('dbo.StaffLeaveLedger', 'U') IS NOT NULL DROP TABLE dbo.StaffLeaveLedger;
IF OBJECT_ID('dbo.HospitalHolidays', 'U') IS NOT NULL DROP TABLE dbo.HospitalHolidays;
IF OBJECT_ID('dbo.HospitalWorkCalendars', 'U') IS NOT NULL DROP TABLE dbo.HospitalWorkCalendars;
IF COL_LENGTH('dbo.StaffMembers', 'WeeklyOff') IS NOT NULL ALTER TABLE dbo.StaffMembers DROP COLUMN WeeklyOff;
PRINT 'Rolled back 121';
