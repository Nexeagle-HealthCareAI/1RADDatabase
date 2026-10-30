# archive/ — never applied

These unnumbered scripts used to sit in `schema/`. The Azure DevOps pipeline and
`local-dev/init-db.sh` ran *everything* in `schema/` after script 95, while the GitHub
workflow ran only `NN_*.sql` — so environments drifted, and
`drop_all_staff_tables.sql` (now `DANGER_drop_all_staff_tables.sql`) wiped the whole
HR/payroll module on every Azure or local build.

Since Oct 2026 the only apply path is `deploy/apply-migrations.sh`, which runs
`schema/NN_*.sql` and `data/*.sql` and nothing else. Nothing in this folder is run.

| File | What it was | Status |
| --- | --- | --- |
| add_daily_token_number.sql | ROW_NUMBER token backfill retired by script 28 | unsafe on populated DBs — do not run |
| add_payroll_draft_status_and_expense_link.sql | twin of 34 | superseded |
| add_payroll_leave_policy_and_employee_code.sql | predecessor of 32 + 33 | superseded |
| add_staff_attendance_and_leave_tables.sql | third copy of 35 | superseded |
| add_staff_document_blob_path.sql, add_staff_photo_columns.sql | folded into 31 | superseded |
| bundle_47_to_51_offline_b1_b2.sql | SSMS one-shot copy of 47–51 | superseded |
| create_staff_child_tables.sql | older staff design; creates stray `HospitalLeavePolicy` | do not run |
| diagnose_study_upload_500.sql | read-only diagnostic | safe to run by hand |
| drop_staff_board_access.sql | drops a never-created column | no-op |
| DANGER_drop_all_staff_tables.sql | "one-shot reset" that drops every HR table | destroys data — never run |

To change the schema, add the next numbered script in `schema/` (guarded /
idempotent) plus a rollback in `rollback/`, and the matching entity property in 1RADAPI.
