# Liquibase Schema

Database schema migrations for a PostgreSQL 17 database managed with Liquibase.
The repository also demonstrates how to create a monitoring role for Datadog and
an administrative PostgreSQL login role through Liquibase changesets.

## What Is Included

- PostgreSQL 17 service configuration in `docker-compose.yml`
- Liquibase master changelog in `changelog/db.changelog.xml`
- A `users` table migration
- A read-only `datadog` monitoring role with the `pg_monitor` role granted
- An `admin` login role with PostgreSQL `SUPERUSER` privileges
- GitHub Actions validation and migration workflow in `.github/workflows/liquibase.yml`

## Prerequisites

- Docker Desktop with Docker Compose
- Liquibase 5.0.3 or a compatible Liquibase installation
- Java 21 when running Liquibase locally
- PostgreSQL JDBC driver 42.7.11

The JDBC driver is ignored by Git and must be downloaded locally. GitHub Actions
downloads it automatically.

## Start PostgreSQL

From the repository root, start the database container:

```powershell
docker compose up -d postgres
```

The local database is available at `localhost:5432` with these development
credentials:

| Setting | Value |
| --- | --- |
| Database | `liquibase_demo` |
| Username | `postgres` |
| Password | `postgres` |
| Host port | `5432` |

These credentials are intended only for local development and CI.

## Download the JDBC Driver

Create the ignored driver directory and download the PostgreSQL JDBC driver:

```powershell
New-Item -ItemType Directory -Force liquibase_libs
Invoke-WebRequest `
	-Uri "https://jdbc.postgresql.org/download/postgresql-42.7.11.jar" `
	-OutFile "liquibase_libs/postgresql.jar"
```

## Run Migrations Locally

The admin changeset uses the `ADMIN_PASSWORD` environment variable. Set it for
the current terminal session before running Liquibase:

```powershell
$env:ADMIN_PASSWORD = "replace-with-a-secure-local-password"
```

Validate the changelog:

```powershell
liquibase `
	--classpath=liquibase_libs/postgresql.jar `
	--defaultsFile=liquibase.properties `
	validate
```

Review pending changes:

```powershell
liquibase `
	--classpath=liquibase_libs/postgresql.jar `
	--defaultsFile=liquibase.properties `
	status --verbose
```

Apply the migrations:

```powershell
liquibase `
	--classpath=liquibase_libs/postgresql.jar `
	--defaultsFile=liquibase.properties `
	update
```

Remove the password from the current PowerShell session when finished:

```powershell
Remove-Item Env:ADMIN_PASSWORD
```

Liquibase records applied changesets in the PostgreSQL `databasechangelog`
table. Do not edit a changeset after it has been applied. Create a new numbered
changeset instead; editing an applied changeset changes its checksum and causes
future validation to fail.

## Changelog

The master changelog includes these changesets in order:

| Changeset | Purpose |
| --- | --- |
| `001` | Creates the `users` table with `id` and `name` columns |
| `002-create-datadog-user` | Creates the `datadog` login role and grants monitoring/read access |
| `003-create-admin-user` | Creates or updates the `admin` login role with `SUPERUSER` privileges |

The `admin` role is deliberately powerful. Use a strong secret and restrict its
use to administration tasks. The Datadog password is applied separately in CI
after the role is created.

## GitHub Actions

The workflow runs on pushes and pull requests. It starts PostgreSQL, installs
Liquibase 5.0.3, downloads the JDBC driver, validates the changelog, applies
pending changes, and verifies that the database is up to date.

Configure these repository secrets before expecting the workflow to complete:

- `ADMIN_PASSWORD`: password for the administrative `admin` role
- `DATADOG_PASSWORD`: password assigned to the Datadog monitoring role

The same `ADMIN_PASSWORD` must be available to both the `update` step and the
later `status`/`validate` steps. This keeps Liquibase's changeset checksum
calculation consistent.

## Repository Layout

```text
.
|-- .github/workflows/liquibase.yml
|-- changelog/
|   |-- db.changelog.xml
|   `-- changes/
|-- docker-compose.yml
|-- Dockerfile
|-- liquibase.properties
|-- liquibase_libs/
|-- sql/
`-- tests/
```

The active migrations are under `changelog/`. The current Dockerfile is an
optional Liquibase image definition and is not used by the GitHub Actions
workflow; the workflow installs Liquibase directly.

## Useful Commands

Check the working tree for whitespace errors:

```powershell
git diff --check
```

Stop the local PostgreSQL container:

```powershell
docker compose down
```

Remove the local database volume as well when a clean database is required:

```powershell
docker compose down -v
```
