-- Migration: 56_one_default_hospital_per_user.sql
-- Description: Enforces "at most one default UserHospitalMapping per user".
--
-- Why this matters
--   UserHospitalMappings carries an IsDefault flag that LoginCommandHandler
--   uses to pick the user's "landing" hospital on sign-in. Historically the
--   schema didn't prevent two rows for the same UserId from both being
--   IsDefault=1 — and DeployInfrastructure used to stamp IsDefault=1 on
--   every founder mapping. If someone founded two centres (or had stale
--   data from a partial migration), login's FirstOrDefault(IsDefault)
--   would land in a non-deterministic hospital depending on EF's emit
--   order. Same identity, different hospital between logins.
--
--   This migration first repairs any existing double-default rows
--   (keeping the earliest-assigned mapping as the canonical default),
--   then installs a filtered unique index so the database can never get
--   back into that state.
--
-- Safe to re-run: the IF NOT EXISTS guard skips the index creation if
-- already applied; the cleanup pass is a no-op when no duplicates exist.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Step 1: repair any pre-existing duplicates. For each UserId that has
-- more than one IsDefault=1 row, keep the earliest-assigned (MappingId
-- as tiebreak) and demote the rest.
WITH ranked AS (
    SELECT MappingId,
           ROW_NUMBER() OVER (
               PARTITION BY UserId
               ORDER BY AssignedAt ASC, MappingId ASC
           ) AS rn
      FROM [dbo].[UserHospitalMappings]
     WHERE IsDefault = 1
)
UPDATE uhm
   SET IsDefault = 0
  FROM [dbo].[UserHospitalMappings] uhm
  JOIN ranked r ON r.MappingId = uhm.MappingId
 WHERE r.rn > 1;
GO

-- Step 2: backfill IsDefault for users who have no default at all.
-- Mark their earliest-assigned mapping as default so login is
-- deterministic without relying on the fallback path.
WITH no_default AS (
    SELECT UserId
      FROM [dbo].[UserHospitalMappings]
     GROUP BY UserId
    HAVING SUM(CAST(IsDefault AS INT)) = 0
),
first_per_user AS (
    SELECT uhm.MappingId,
           ROW_NUMBER() OVER (
               PARTITION BY uhm.UserId
               ORDER BY uhm.AssignedAt ASC, uhm.MappingId ASC
           ) AS rn
      FROM [dbo].[UserHospitalMappings] uhm
      JOIN no_default nd ON nd.UserId = uhm.UserId
)
UPDATE uhm
   SET IsDefault = 1
  FROM [dbo].[UserHospitalMappings] uhm
  JOIN first_per_user f ON f.MappingId = uhm.MappingId
 WHERE f.rn = 1;
GO

-- Step 3: install the filtered unique index so the invariant holds going
-- forward. SQL Server enforces this only on rows where IsDefault = 1,
-- which is exactly the constraint we want — any number of non-default
-- mappings per user are still allowed.
IF NOT EXISTS (
    SELECT 1
      FROM sys.indexes
     WHERE name = 'UX_UHM_DefaultPerUser'
       AND object_id = OBJECT_ID(N'[dbo].[UserHospitalMappings]')
)
BEGIN
    CREATE UNIQUE INDEX [UX_UHM_DefaultPerUser]
        ON [dbo].[UserHospitalMappings]([UserId])
     WHERE [IsDefault] = 1;

    PRINT 'Created filtered unique index UX_UHM_DefaultPerUser on UserHospitalMappings(UserId) WHERE IsDefault = 1.';
END
ELSE
BEGIN
    PRINT 'Filtered unique index UX_UHM_DefaultPerUser already exists. Skipping.';
END
GO
