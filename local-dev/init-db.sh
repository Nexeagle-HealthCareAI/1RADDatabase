#!/usr/bin/env bash
# Build a full 1RadDatabase inside the local SQL Server container from scratch.
# Mirrors the exact apply order the Azure pipeline uses: schema/*.sql then data/*.sql.
#
#   docker compose -f local-dev/docker-compose.yml up -d
#   ./local-dev/init-db.sh
#
# Re-runnable: scripts are guard-clause / idempotent, so running twice is safe.
set -euo pipefail

SA_PASSWORD="${MSSQL_SA_PASSWORD:-Strong_Pass_123!}"
DB_NAME="${DB_NAME:-1RadDatabase}"
NETWORK="1rad-net"
SQL_HOST="1rad-sql"

# Repo root = parent of this script's dir (so it works from anywhere).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# sqlcmd runs inside a throwaway tools container on the same network as the DB,
# with the repo mounted read-only at /repo. No local sqlcmd install needed.
sqlcmd() {
  docker run --rm --network "$NETWORK" -v "$REPO_ROOT:/repo:ro" \
    mcr.microsoft.com/mssql-tools18 \
    /opt/mssql-tools18/bin/sqlcmd -S "$SQL_HOST" -U sa -P "$SA_PASSWORD" -C -b "$@"
}

echo "Waiting for SQL Server to accept connections..."
for i in $(seq 1 40); do
  if sqlcmd -Q "SELECT 1" >/dev/null 2>&1; then break; fi
  sleep 2
  if [ "$i" -eq 40 ]; then echo "ERROR: SQL Server never became ready." >&2; exit 1; fi
done
echo "  ready."

echo "Ensuring database [$DB_NAME] exists..."
sqlcmd -Q "IF DB_ID('$DB_NAME') IS NULL CREATE DATABASE [$DB_NAME];"

echo "Applying schema scripts..."
while IFS= read -r f; do
  rel="${f#"$REPO_ROOT"/}"
  echo "  -> $rel"
  sqlcmd -d "$DB_NAME" -I -i "/repo/$rel"
done < <(find "$REPO_ROOT/schema" -type f -name "*.sql" | sort)

if [ -d "$REPO_ROOT/data" ]; then
  echo "Applying data scripts..."
  while IFS= read -r f; do
    rel="${f#"$REPO_ROOT"/}"
    [[ "$rel" == *.sql ]] || continue
    echo "  -> $rel"
    sqlcmd -d "$DB_NAME" -I -i "/repo/$rel"
  done < <(find "$REPO_ROOT/data" -type f -name "*.sql" | sort)
fi

echo ""
echo "DONE. Connect with:"
echo "  Server=localhost,1433;Database=$DB_NAME;User Id=sa;Password=$SA_PASSWORD;TrustServerCertificate=True;"
