# Local database

A disposable SQL Server 2022 in Docker, built exactly the way Dev and Prod are.

```bash
docker compose -f local-dev/docker-compose.yml up -d
./local-dev/init-db.sh
```

`init-db.sh` calls `deploy/apply-migrations.sh`, the single apply path used by every
environment: it runs `schema/NN_*.sql` then `data/*.sql`, records each in
`dbo.__MigrationHistory`, and skips anything already applied. Scripts from 96 on run
inside one transaction each. Unnumbered scripts are in `archive/` and are never run.

Point the API at it with
`ConnectionStrings__DefaultConnection="Server=localhost,1433;Database=1RadDatabase;User Id=sa;Password=<MSSQL_SA_PASSWORD>;TrustServerCertificate=True;"`
(set it as an environment variable or user secret — never commit it to `appsettings.*.json`).

Reset: `docker compose -f local-dev/docker-compose.yml down -v`.

## Adding a migration

1. Next number in `schema/` (e.g. `97_short_name.sql`), guarded so a re-run is harmless
   (`IF COL_LENGTH(...) IS NULL`, `IF OBJECT_ID(...) IS NULL`, …). CI re-runs new
   scripts to check this.
2. A matching `rollback/97_rollback_short_name.sql`.
3. The matching entity property in 1RADAPI in the same change — the API's CI compares
   the EF model with a database built from these scripts.
