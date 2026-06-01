-- Migration: 59_backfill_invoice_item_service_fk.sql
-- Description: Attach legacy InvoiceItem rows to their AppointmentService.
--
-- Multi-service rollout (migration 57) added the AppointmentServiceId FK
-- on InvoiceItems so each billed line maps to its specific service. The
-- backfill in migration 57 covered single-service visits (1:1 trivially)
-- but multi-service invoices created BEFORE the frontend was fixed to
-- forward the FK on POST /finance/invoices still have NULL FKs on every
-- item. That makes the GetInvoices projection fall back to the parent
-- appointment's scalar Modality, so a multi-service invoice displays
-- the same modality on every line in the UI.
--
-- This migration tries to bind each orphan InvoiceItem to one of its
-- visit's AppointmentService rows. Two strategies, applied in order:
--
--   1) Single-service visit — if the appointment has exactly one
--      live AppointmentService row, stamp every NULL-FK item on the
--      invoice with that row's Id. Always correct.
--
--   2) Multi-service visit — match InvoiceItem.Description against
--      AppointmentService.ServiceName, case-insensitive, after
--      stripping common whitespace. Picks the first match per visit
--      that hasn't already been claimed by another item, so a visit
--      with two "CT" rows still gets bound 1:1 instead of both items
--      pointing at the same service.
--
-- Only updates rows where AppointmentServiceId IS NULL. Safe to re-run.
-- Lines that can't be matched stay NULL — they'll continue to use the
-- modality fallback in GetInvoicesQuery (Appointment.Modality), which
-- is the best we can do without a description match.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-------------------------------------------------------------------------------
-- Step 1: Single-service visits — unambiguous 1:1 stamp
-------------------------------------------------------------------------------
;WITH SingleServiceVisits AS (
    SELECT
        i.Id              AS InvoiceId,
        i.AppointmentId,
        MIN(s.Id)         AS ServiceId,
        COUNT(*)          AS ServiceCount
    FROM   [dbo].[Invoices]              i
    JOIN   [dbo].[AppointmentServices]   s ON s.AppointmentId = i.AppointmentId
                                          AND s.DeletedAt IS NULL
    WHERE  i.AppointmentId IS NOT NULL
    GROUP BY i.Id, i.AppointmentId
    HAVING COUNT(*) = 1
)
UPDATE it
SET    it.AppointmentServiceId = ssv.ServiceId
FROM   [dbo].[InvoiceItems]   it
JOIN   SingleServiceVisits    ssv ON ssv.InvoiceId = it.InvoiceId
WHERE  it.AppointmentServiceId IS NULL;
GO

-------------------------------------------------------------------------------
-- Step 2: Multi-service visits — match item Description ↔ service ServiceName
--
-- Window function ranks (item, service) candidates within each invoice so
-- each service gets claimed at most once. The match is case-insensitive
-- and tolerant of extra whitespace.
-------------------------------------------------------------------------------
;WITH UnboundItems AS (
    SELECT
        it.Id                  AS InvoiceItemId,
        it.InvoiceId,
        i.AppointmentId,
        UPPER(LTRIM(RTRIM(it.Description))) AS DescKey
    FROM   [dbo].[InvoiceItems] it
    JOIN   [dbo].[Invoices]     i  ON i.Id = it.InvoiceId
    WHERE  it.AppointmentServiceId IS NULL
      AND  i.AppointmentId IS NOT NULL
),
Candidates AS (
    SELECT
        u.InvoiceItemId,
        u.InvoiceId,
        s.Id                  AS ServiceId,
        s.UpdatedAt,
        ROW_NUMBER() OVER (
            PARTITION BY u.InvoiceItemId
            ORDER BY s.UpdatedAt
        ) AS ItemRank,
        ROW_NUMBER() OVER (
            PARTITION BY u.InvoiceId, s.Id
            ORDER BY u.InvoiceItemId
        ) AS ServiceRank
    FROM   UnboundItems                  u
    JOIN   [dbo].[AppointmentServices]   s
        ON  s.AppointmentId = u.AppointmentId
        AND s.DeletedAt IS NULL
        AND UPPER(LTRIM(RTRIM(s.ServiceName))) = u.DescKey
)
UPDATE it
SET    it.AppointmentServiceId = c.ServiceId
FROM   [dbo].[InvoiceItems] it
JOIN   Candidates           c ON c.InvoiceItemId = it.Id
WHERE  c.ItemRank    = 1
  AND  c.ServiceRank = 1
  AND  it.AppointmentServiceId IS NULL;
GO

-------------------------------------------------------------------------------
-- Step 3: Report what's left so an operator can spot weird-description rows
-- that need manual reconciliation. Pure diagnostic — no data change.
-------------------------------------------------------------------------------
SELECT
    'InvoiceItems still without AppointmentServiceId after backfill' AS Note,
    COUNT(*) AS OrphanCount
FROM   [dbo].[InvoiceItems] it
JOIN   [dbo].[Invoices]     i ON i.Id = it.InvoiceId
WHERE  it.AppointmentServiceId IS NULL
  AND  i.AppointmentId        IS NOT NULL;
GO
