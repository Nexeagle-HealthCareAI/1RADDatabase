#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Apply 1Rad schema migrations to a SQL Server running in a Docker container.
# The ONE apply path for every environment (Dev VM, Prod VM, CI validation).
#
#   SQL_CONTAINER   container name/id running SQL Server        (default: sqlserver)
#   SA_PASSWORD     sa password                                  (required)
#   DB_NAME         database                                     (default: 1RadDatabase)
#   DEPLOY_DIR      folder holding NN_*.sql and data/*.sql       (default: script's ../)
#   DRY_RUN         "true" = list what would run, change nothing
#
# Rules (Oct 2026 gap analysis P3-1/P3-2):
#   * Only schema/NN_*.sql / NNN_*.sql and data/*.sql are ever applied (numeric order).
#     Unnumbered one-off scripts live in archive/ and are never run.
#   * dbo.__MigrationHistory is the ledger; an applied script is never re-run.
#   * Each script (from WRAP_FROM, default 96) runs inside ONE transaction together with its ledger row
#     (SET XACT_ABORT ON). A failure rolls back the whole script, so the database
#     is never left half-migrated and unrecorded. Stops at the first failure.
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SQL_CONTAINER="${SQL_CONTAINER:-sqlserver}"
DB_NAME="${DB_NAME:-1RadDatabase}"
DRY_RUN="${DRY_RUN:-false}"
# Scripts numbered below WRAP_FROM predate the transaction wrapper and are already
# applied on Dev/Prod; on a fresh build they run unwrapped, exactly as they always have.
WRAP_FROM="${WRAP_FROM:-96}"
: "${SA_PASSWORD:?SA_PASSWORD is required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="${DEPLOY_DIR:-$SCRIPT_DIR/..}"

SQLCMD=/opt/mssql-tools18/bin/sqlcmd
docker exec "$SQL_CONTAINER" test -x "$SQLCMD" 2>/dev/null || SQLCMD=/opt/mssql-tools/bin/sqlcmd

run_sql() { docker exec "$SQL_CONTAINER" "$SQLCMD" -S localhost -U sa -P "$SA_PASSWORD" -C -b "$@"; }
# -I = QUOTED_IDENTIFIER ON, required by the filtered indexes (the retired Azure build used it too).
run_sql_stdin() { docker exec -i "$SQL_CONTAINER" "$SQLCMD" -S localhost -U sa -P "$SA_PASSWORD" -C -b -I "$@"; }

echo "=== Target: container '$SQL_CONTAINER', database '$DB_NAME' (dry run: $DRY_RUN) ==="

if [ "$DRY_RUN" != "true" ]; then
  run_sql -Q "IF DB_ID('$DB_NAME') IS NULL BEGIN CREATE DATABASE [$DB_NAME]; PRINT 'Created $DB_NAME'; END"
  run_sql -d "$DB_NAME" -Q "
    IF OBJECT_ID('dbo.__MigrationHistory') IS NULL
      CREATE TABLE dbo.__MigrationHistory (
        Id         INT IDENTITY(1,1) PRIMARY KEY,
        ScriptName NVARCHAR(255) NOT NULL UNIQUE,
        AppliedAt  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        DurationMs INT NULL
      );" > /dev/null
fi

is_applied() {
  [ "$DRY_RUN" = "true" ] && { echo 0; return; }
  run_sql -d "$DB_NAME" -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.__MigrationHistory WHERE ScriptName = N'$1';" | tr -d ' \r\n'
}

APPLIED=0; SKIPPED=0
apply_one() {
  local path="$1" name="$2"
  if [ "$(is_applied "$name")" = "1" ]; then
    echo "  ⏭  skip    $name"; SKIPPED=$((SKIPPED+1)); return 0
  fi
  if [ "$DRY_RUN" = "true" ]; then
    echo "  •  would apply $name"; APPLIED=$((APPLIED+1)); return 0
  fi
  local start end ok
  start=$(date +%s%3N)
  local num wrap=1
  num=$(basename "$path" | sed -nE 's/^([0-9]{2,3})_.*/\1/p')
  if [[ "$num" =~ ^[0-9]{2,3}$ ]] && [ "$((10#$num))" -lt "$WRAP_FROM" ]; then wrap=0; fi
  if grep -qiE '^[[:space:]]*BEGIN[[:space:]]+TRAN' "$path"; then wrap=0; fi
  if [ "$wrap" = "0" ]; then
    # Legacy script, or one that manages its own transaction(s): run as-is, then record it.
    if run_sql_stdin -d "$DB_NAME" < "$path" && \
       run_sql -d "$DB_NAME" -Q "INSERT INTO dbo.__MigrationHistory (ScriptName) VALUES (N'$name');" > /dev/null; then
      ok=1
    else ok=0; fi
  else
    # Wrap the script (all of its GO batches) and its ledger row in one transaction.
    # -b aborts on the first error; the session then closes and SQL Server rolls back.
    if { printf 'SET XACT_ABORT ON;\nBEGIN TRANSACTION;\nGO\n'
       cat "$path"
       printf '\nGO\nINSERT INTO dbo.__MigrationHistory (ScriptName) VALUES (N'"'"'%s'"'"');\nCOMMIT TRANSACTION;\nGO\n' "$name"
     } | run_sql_stdin -d "$DB_NAME"; then ok=1; else ok=0; fi
  fi
  if [ "$ok" = "1" ]; then
    end=$(date +%s%3N)
    run_sql -d "$DB_NAME" -Q "UPDATE dbo.__MigrationHistory SET DurationMs = $((end - start)) WHERE ScriptName = N'$name';" > /dev/null
    echo "  ✅ applied $name ($((end - start)) ms)"; APPLIED=$((APPLIED+1))
  else
    echo "  ❌ FAILED  $name — not recorded (wrapped scripts are rolled back). Stopping." >&2
    exit 1
  fi
}

echo "=== Schema scripts ==="
shopt -s nullglob
SCHEMA_DIR="$DEPLOY_DIR"; [ -d "$DEPLOY_DIR/schema" ] && SCHEMA_DIR="$DEPLOY_DIR/schema"
# NN_ or NNN_ prefixes, in numeric order (so 100_ sorts after 99_).
for name in $(ls "$SCHEMA_DIR" | grep -E '^[0-9]{2,3}_.*\.sql$' | sort -V); do
  apply_one "$SCHEMA_DIR/$name" "$name"
done

echo "=== Data scripts ==="
for f in $(printf '%s\n' "$DEPLOY_DIR"/data/*.sql | sort); do
  apply_one "$f" "data/$(basename "$f")"
done

echo "=== Done: applied $APPLIED, skipped $SKIPPED ==="
if [ "$DRY_RUN" != "true" ]; then
  run_sql -d "$DB_NAME" -h -1 -W -Q "SET NOCOUNT ON; SELECT 'Tables: ' + CAST(COUNT(*) AS varchar) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE';"
fi
