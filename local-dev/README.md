# Local & CI database — cutting Azure SQL dev cost

The goal: stop paying for an always-on Azure SQL dev database during rapid
development and testing. Your 84 schema scripts are plain, idempotent T-SQL with
no Azure-only constructs, so they run identically in a free, disposable SQL
Server container. This folder makes that the default for dev and CI, and keeps
real Azure SQL only where cloud parity actually matters (staging).

## Where the cost goes today

- **Unit tests** (`1Rad.UnitTests`) already use EF Core `UseInMemoryDatabase` —
  they don't touch Azure, so they aren't the cost.
- **The cost is the shared, always-on Dev Azure SQL** (`easyhmserver.database.windows.net / 1RadDatabase`).
  `oneRadDB/azure-pipelines.yml` re-applies all schema scripts to it on every
  push, and it bills 24/7 at a provisioned tier whether or not anyone is using it.

## The three changes

### 1. Local dev DB in Docker (developers stop hitting Azure)

```bash
docker compose -f local-dev/docker-compose.yml up -d
./local-dev/init-db.sh
```

The API now points at this container automatically in Development — see
"How the API picks its database" below. No manual connection-string editing.

Reset anytime: `docker compose -f local-dev/docker-compose.yml down -v && docker compose -f local-dev/docker-compose.yml up -d && ./local-dev/init-db.sh`

### How the API picks its database (the switch that lets Azure pause)

ASP.NET Core layers `appsettings.{ASPNETCORE_ENVIRONMENT}.json` over the base
`appsettings.json`, so the database is chosen purely by environment — no code
change:

| Environment | `DefaultConnection` source | Hits |
|-------------|----------------------------|------|
| **Development** (default for `dotnet run`) | `appsettings.Development.json` | **Local container** (`localhost,1433`) |
| **Staging** (`ASPNETCORE_ENVIRONMENT=Staging`) | `appsettings.Staging.json` | **Azure SQL** `easyhmserver/1RadDatabase` |
| **Production** | `appsettings.Production.json` | Azure SQL (prod) |

Because Development no longer touches Azure SQL, nothing keeps the Azure dev
database awake — its serverless compute auto-pauses and the ₹11.6k vCore line
drops toward storage-only.

**Staging password is NOT committed.** `appsettings.Staging.json` has a
`__SET_VIA_ENV__` placeholder. The staging host/pipeline must supply the real
value via an environment variable, which fully overrides the JSON:

```bash
export ConnectionStrings__DefaultConnection="Server=tcp:easyhmserver.database.windows.net,1433;Initial Catalog=1RadDatabase;Encrypt=True;User ID=easyHMSAdmin;Password=<rotated-password>;"
ASPNETCORE_ENVIRONMENT=Staging dotnet run
```

(`__` maps to the `:` config separator, so this targets `ConnectionStrings:DefaultConnection`.)

Run the API against the local container (the normal dev loop):

```bash
docker compose -f local-dev/docker-compose.yml up -d   # once
./local-dev/init-db.sh                                 # once (or after reset)
# then, from the 1RadAPI repo:
dotnet run --project 1RadAPI                            # Development by default
```

### 2. Validate schema in CI against a container, not Azure

Paste `local-dev/validate-db-stage.yml` as the first stage of
`oneRadDB/azure-pipelines.yml`, and make `DevDB` depend on it
(`dependsOn: ValidateDB`). Now every push proves all 84 scripts apply cleanly
**from an empty database** at zero Azure cost — catching drift the current
pipeline can't, because it only ever mutates a long-lived DB. Azure SQL is
touched only after validation passes.

### 3. Convert the remaining Dev Azure SQL to Serverless auto-pause

You still want one real Azure SQL for staging/integration parity — but it
shouldn't bill while idle. Switch it to the serverless compute tier so it
auto-pauses when unused and you pay only for storage while paused:

```bash
az sql db update \
  -g <resource-group> -s easyhmserver -n 1RadDatabase \
  --edition GeneralPurpose --compute-model Serverless --family Gen5 \
  --capacity 4 --min-capacity 0.5 --auto-pause-delay 60
```

`--auto-pause-delay 60` = pause after 60 min idle (minimum). For bursty
dev/test this is typically the single largest line-item reduction. Confirm your
current SKU first in Azure portal → the DB → **Cost Analysis / Compute + storage**;
if it's Business Critical or a high vCore count, that's your $15k.

## Optional: make integration tests use the container too

`1Rad.UnitTests/IntegrationTests` currently uses `UseInMemoryDatabase`, which
isn't a real relational engine (no real constraints, SQL functions, or
transactions) and hides SQL-specific bugs. For those tests, switch to
`UseSqlServer(...)` pointed at the container (the
[Testcontainers](https://dotnet.testcontainers.org/) library can start/stop it
per test run automatically). Keep the fast InMemory tests as-is for pure
unit-level logic.

## Parity limits to remember

The container is full SQL Server, not Azure SQL. A small set of Azure-only
features won't exist locally (elastic queries, some Azure DMVs, Entra/Managed
Identity auth). Your scripts were scanned and use **none** of these today. If
that changes, keep those specific tests on the staging Azure SQL.

## Security note (do separately, soon)

`1RadAPI/1RadAPI/appsettings.Development.json` contains a **real** Azure Storage
account key and DB password committed to git. Rotate both and move secrets to
.NET user-secrets locally and pipeline variable groups in CI.
