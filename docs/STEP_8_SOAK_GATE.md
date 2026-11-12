# Multi-service rollout — soak gate before step 8

Step 8 of the multi-service rollout drops the legacy scalar columns
`Appointment.Service` and `Appointment.Modality` (along with the
matching DTO fields, handler reads and frontend renders that still
fall back to them). This is purely cleanup — there is **no user-
visible feature** behind it, and it is the one step that can lose data
if shipped before older clients have stopped reading the scalars.

This document is the gate. **Do not run migration 58 (the column-drop
migration) until every item below is green.**

Steps 1–7 + A + B are already merged; this is the test plan for the
rollout that's already in place, plus the conditions that must hold
for at least one full release window before step 8 ships.

---

## 1. Per-layer manual smoke test

Run this against a staging deploy with at least one multi-service
appointment seeded (X-ray + CT + USG on one visit) and at least one
legacy single-service appointment from before migration 57. The
seeded data exercises both the v1 fallback path and the new chip-
stack / multi-line path.

### 1.1 Booking — AppointmentBoard

| | Test | Expected |
|---|---|---|
| 1 | Open the booking drawer, pick X-RAY, type a service, set an amount. | Draft preview row appears in the new visit-tray dashed blue. |
| 2 | Click **+ Add another service**. | Draft is committed as a chip; the inputs clear (modality stays on X-RAY). |
| 3 | Change modality to CT, type a service, set amount. | Tray shows two chips: the X-ray (committed) and CT (draft preview). Tray header reads "2 items · ₹total". |
| 4 | Click DEPLOY MISSION. | Visit created. POST payload's `services` array has 2 entries; `service`/`modality`/`amount` scalars mirror line 1. |
| 5 | Reopen the visit's Edit drawer. | Primary line populates the inputs at the top; second line is a SAVED chip in the tray with `id` populated. |
| 6 | Add a 3rd service in the Edit drawer, remove the 2nd, save. | PUT payload's `services` array has the primary (with `_primaryServiceId`), the new line (`id: null`), and is missing the removed line. Server soft-deletes the removed line (`DeletedAt = now`). |
| 7 | Book a single-service appointment the old way (one modality, one service, no "+ Add"). | Visit created. POST `services` has 1 entry. Worklist row looks identical to a v1 row. |

### 1.2 Worklist row (desktop) — AppointmentBoard

| | Test | Expected |
|---|---|---|
| 8 | Find the multi-service visit on the worklist. | Modality area shows chip stack (`[X-RAY] [CT] [USG]`), primary service name, `+2 more` chip, and a green `0 / 3 reported` badge. |
| 9 | Pick `CT` from the modality filter. | Multi-service visit stays visible (any-service match). Single-service X-ray visit disappears. |
| 10 | Open AppointmentCard on mobile/tablet width. | Service tile shows primary + `+N more` + progress badge underneath; modality tile renders chip stack. |
| 11 | Find a legacy single-service visit (booked before migration 57). | Renders exactly as a single-service multi-rollout visit — one modality chip, no `+N more`, no progress badge (single-service short-circuit in `getReportProgressLabel`). |

### 1.3 Technician — TechnicianPage

| | Test | Expected |
|---|---|---|
| 12 | Filter the worklist to `CT`. | Multi-service visit shows; modality column renders compact chip stack. |
| 13 | Click the row → enter workspace. | Sidebar shows a new "Services on this visit (3)" panel with one card per service (modality chip + service name + status pill + Mark Scanned button). |
| 14 | Click **Mark scanned** on the X-ray row. | Service status flips to SCANNED, green pill, Mark button hidden. Worklist row's progress badge ticks forward. Parent visit status doesn't yet flip to "scanned" (only flips when ALL services are scanned). |
| 15 | Mark CT + USG scanned. | Parent `Appointment.Status` becomes `scanned` (server rollup). |

### 1.4 Doctor — DoctorBoard

| | Test | Expected |
|---|---|---|
| 16 | Find the multi-service visit on the doctor's worklist. | Modality cell: chip stack + primary service name + `+2 more` + progress badge. |
| 17 | Click the row to open the reporting workspace. | Navigates to `/reporting/<appointmentId>?serviceId=<firstUnreportedServiceId>`. |
| 18 | If all services are already finalised, repeat 17. | Navigates with the first service's id (still scoped). |

### 1.5 Reporting — ReportingPage

| | Test | Expected |
|---|---|---|
| 19 | Open the multi-service visit. | Service-picker tab strip appears in the header with one tab per service. Active tab is highlighted blue. |
| 20 | Type findings + impression, wait 45s. | Autosave POST `/reporting/save` carries `appointmentServiceId` matching the active tab. Server upserts the report scoped to (`appointmentId`, `appointmentServiceId`). |
| 21 | Click a different service tab. | URL `?serviceId=` updates without remount; editor reloads with that service's report (or empty if none yet). |
| 22 | Finalise the X-ray report. | Server: AppointmentService.Status → REPORTED. Tab gets a green dot. Parent `Appointment.Status` does **not** flip to REPORTED yet (only flips when every live service has a finalised report). |
| 23 | Finalise CT + USG. | Parent flips to REPORTED. |
| 24 | Open a legacy single-service visit. | No tab strip (single line collapses to a normal modality badge). Autosave still works; payload carries `appointmentServiceId` matching the auto-selected primary service. |

### 1.6 DICOM bridge

Requires the bridge running locally pointed at staging, with one
multi-service visit already booked (X-ray + CT) and the corresponding
DICOM studies in Orthanc.

| | Test | Expected |
|---|---|---|
| 25 | Push a DICOM study with Modality=DX (or CR) to Orthanc for a patient with a multi-service visit. | Bridge logs `[MATCH] → service <id> (X-RAY · <name>) — reason: modalityMatch`. |
| 26 | After upload, check StudyAsset row. | `AppointmentServiceId` is stamped to the X-ray service. |
| 27 | Check the X-ray service's status. | `SCANNED` (per-service mark) with `ScanCompletedAt` set. Parent visit's `ScanStartedAt` set (rollup), `ScannedAt` NOT yet set (CT still pending). |
| 28 | Push the CT study. | Bridge attaches to the CT service. Both services scanned ⇒ parent `ScannedAt` stamped. |
| 29 | Repeat 25 against a v1 appointment that lacks `services[]`. | Bridge falls back to `pickBestServiceForStudy → primaryFallback` and stamps the only available service from migration 57's backfill. Parent appointment status path also still works. |

### 1.7 Operations + Patient timeline

| | Test | Expected |
|---|---|---|
| 30 | Open OperationsBoard. Search by the secondary service name (e.g. "CT Head") on a multi-service visit. | Visit surfaces; chip stack rendered. |
| 31 | Open the patient's timeline. | Multi-service entry shows primary + `+N more services` + progress badge inline with the title; mini-list of all services with per-line green dot for finalised lines. |
| 32 | Filter the timeline by modality. | Visit with any matching service stays; others drop. |

---

## 2. Telemetry / log signals to watch

In addition to manual smoke, these must hold over the soak window
(see § 3) before step 8 is safe.

| Signal | What it means | Acceptance threshold |
|---|---|---|
| `GetAppointments` 5xx rate | Multi-service projection broke. | Same or lower than pre-rollout baseline. |
| `SaveReport` 4xx rate (excl. 409) | Service-scoped upsert misroute. | ≤ pre-rollout baseline. |
| `SaveReport` 409 rate | OCC conflicts. New shape gives each service its own `RowVersion` — 409s should *drop* on multi-service visits. | ≤ pre-rollout baseline. Steady-state drop is the expected win. |
| `Study/upload` 4xx rate | Bridge sending a stale `AppointmentServiceId`. | ≤ pre-rollout baseline. |
| `appointment.Service IS NULL` in DB | Some code path wrote a multi-service appointment without populating the scalar mirror. **Blocks step 8.** | Zero rows over soak window. |
| `appointment.Modality IS NULL` in DB | Same. | Zero rows. |
| Number of `AppointmentService` rows per appointment | Average should climb above 1 as multi-service usage ramps. | Use as a usage indicator, not a gate. |
| Bridge `[MATCH] No service line resolved` warnings | Bridge couldn't pick a service — falls back to appointment-level. | Some are fine (legacy visits); a spike indicates the matcher's modality aliases are missing a case (file a fix). |

---

## 3. Soak window — when step 8 is safe

Step 8 may schedule **only when ALL of these are true**:

1. **Two full calendar weeks** have passed since steps 1–7 + A + B
   first shipped to production, with no rollback in between. This
   covers one full app-store / PWA update cycle so any stale-cache
   PWA install has had a chance to refresh.
2. Section 1's smoke test runs green against a fresh staging deploy
   on the day step 8 ships (not just historically once at rollout).
3. Section 2's telemetry signals have held within thresholds for the
   full two weeks — in particular, **zero rows** with
   `Appointment.Service IS NULL OR Appointment.Modality IS NULL`.
4. The `outbox_queue` (frontend offline queue) shows zero items
   older than 7 days carrying the v1 scalar-only `APPOINTMENT_CREATE`
   /`APPOINTMENT_UPDATE` shape. (Old offline drafts would replay
   into the scalar fields after column drop — drainage gates 8.)
5. The dicom-bridge install on every site running it has been
   updated to the post-step-7 release. (Older bridges still write
   to the scalar `modality` field; the column drop would break them.)
6. A `git log` query confirms no PR has shipped between rollout and
   today that re-introduces a read of `Appointment.Service` /
   `.Modality` outside the denormalisation-mirror path. Search:
   `grep -rn 'appointment\.\(Service\|Modality\)' --include='*.cs'`
   in 1RadAPI and `grep -rn 'app\.\(modality\|service\)\b'
   --include='*.jsx' --include='*.js'` in easyrad. Each hit should
   be either inside `Multi-service rollout — backward compat`
   comments OR in the v1 fallback branch of `getServiceLines`.

If any condition fails, push the gate by 7 days and re-evaluate.

---

## 4. Rollback plan for steps 1-7 + A + B

If a critical bug surfaces after rollout but before step 8:

- **Forward fix is preferred** because rolling the API back below
  step 1 requires also dropping every multi-service `AppointmentService`
  row created during the rollout — they have FK constraints on
  child tables and rollback would orphan them.
- Acceptable forward-fix patterns:
  - Frontend-only revert (disable the new tray / picker / chip stack
    by feature flag) — the API still writes both shapes, so a v1-
    only frontend still works and writes the primary line to both
    the scalar fields and an `AppointmentService` row.
  - Server-side gate that ignores `services[]` in CreateAppointment
    /UpdateAppointment if a flag is off — falls back to scalar
    behaviour. The new entity table stays, the FK columns stay
    null, downstream rows still resolve through `AppointmentId`.
- Step 8 cannot be rolled back without another forward migration
  to re-add the columns + backfill from `AppointmentServices`.
  **This is the core reason step 8 is gated until soak is clean.**

---

## 5. When step 8 finally runs

Migration 58 should:

1. `ALTER TABLE Appointments DROP COLUMN Service`
2. `ALTER TABLE Appointments DROP COLUMN Modality`
3. Remove the matching properties from `Appointment.cs`,
   `AppointmentDto.cs` (CreateAppointmentCommand /
   UpdateAppointmentCommand keep the params but mark them
   `[Obsolete]` for one more release before final removal — gives
   any external integrators a deprecation window).
4. Frontend pass: delete the v1-fallback branch from
   `getServiceLines`. Delete the scalar mirror block from
   AppointmentBoard's `handleBookAppointment` and
   `handleEditAppointment` payload builders.
5. Bridge: delete the `appt.modality` reference in matcher.js's
   `serviceLines` v1 fallback. Same for `pickBestServiceForStudy`.

Run the smoke test from § 1 against staging after the column drop —
every v1-fallback test (rows 11, 24, 29) should still pass against
backfilled appointments because their service lines were stamped by
migration 57, not by scalar inheritance at read time.
