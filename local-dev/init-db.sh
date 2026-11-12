#!/usr/bin/env bash
# Build 1RadDatabase inside the local SQL Server container, the same way the Dev and
# Prod pipelines do: deploy/apply-migrations.sh (schema/NN_*.sql + data/*.sql, ledger,
# one transaction per script). Re-runnable: already-applied scripts are skipped.
#
#   docker compose -f local-dev/docker-compose.yml up -d
#   ./local-dev/init-db.sh
set -euo pipefail

export SA_PASSWORD="${MSSQL_SA_PASSWORD:-Strong_Pass_123!}"   # local throwaway container only
export DB_NAME="${DB_NAME:-1RadDatabase}"
export SQL_CONTAINER="${SQL_CONTAINER:-1rad-sql}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Waiting for SQL Server to accept connections..."
for i in $(seq 1 40); do
  if docker exec "$SQL_CONTAINER" /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -Q "SELECT 1" >/dev/null 2>&1; then break; fi
  sleep 2
  if [ "$i" -eq 40 ]; then echo "ERROR: SQL Server never became ready." >&2; exit 1; fi
done

DEPLOY_DIR="$REPO_ROOT" "$REPO_ROOT/deploy/apply-migrations.sh"

echo ""
echo "DONE. Connect with:"
echo "  Server=localhost,1433;Database=$DB_NAME;User Id=sa;Password=<MSSQL_SA_PASSWORD>;TrustServerCertificate=True;"
