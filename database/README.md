# Database Administration Assets

This directory contains the assets required to provision and seed the
clinical trial administration database.

## Contents

- `sql/` — schema definition and seed data scripts executed in order by the
  bootstrapper:
  1. `vocabulary_tables.sql` — controlled vocabularies (countries,
     recruitment statuses, etc.).
  2. `auth_tables_postgres.sql` — Django authentication and content type
     tables compatible with PostgreSQL.
  3. `clinical_trial_tables.sql` — core trial entities and relationships.
  4. `supporting_objects.sql` — triggers, helper functions, and stored
     procedures supporting the application.
  5. `vocabulary_seed.sql` — initial lookup data for the vocabulary tables.
- `bootstrap.py` — Python script that connects to PostgreSQL, executes the
  schema, and loads the seed data.

## Prerequisites

- Python 3.9+
- [`psycopg2`](https://www.psycopg.org/docs/install.html) (install via
  `pip install psycopg2-binary` if the native build prerequisites are not
  available)
- Access to a PostgreSQL database with privileges to create tables,
  functions, triggers, and insert data.

## Configuration

The bootstrap script accepts a PostgreSQL connection in one of two ways:

1. Provide a full `DATABASE_URL` DSN (e.g. `postgresql://user:pass@localhost:5432/ctms`).
2. Or set the component environment variables:
   - `DB_HOST` (default: `localhost`)
   - `DB_PORT` (default: `5432`)
   - `DB_NAME` (**required**)
   - `DB_USER` (**required**)
   - `DB_PASSWORD` (optional)

## Running the Bootstrap Script

1. Install dependencies (ideally within a virtual environment):

   ```bash
   pip install psycopg2-binary
   ```

2. Export the connection details for your target database:

   ```bash
   export DB_HOST=localhost
   export DB_PORT=5432
   export DB_NAME=ctms
   export DB_USER=postgres
   export DB_PASSWORD=secret
   ```

3. Execute the bootstrapper using the module invocation so the relative paths
   resolve correctly:

   ```bash
   python -m database.bootstrap
   ```

   Alternatively, specify a DSN directly:

   ```bash
   DATABASE_URL="postgresql://postgres:secret@localhost:5432/ctms" \
     python -m database.bootstrap
   ```

On success the script prints progress for each SQL file and exits after the
schema and seed data have been applied.

## Auth Data Migration from MySQL

The `migrate_auth_data.py` utility copies Django authentication and content type
data from the legacy MySQL deployment into the PostgreSQL schema installed by
the bootstrapper. It preserves all primary keys, many-to-many relationships, and
logs any skipped records if uniqueness or primary key conflicts are detected.

### Prerequisites

- [`pymysql`](https://pymysql.readthedocs.io/en/latest/user/installation.html)
- [`psycopg2`](https://www.psycopg.org/docs/install.html) (or
  `psycopg2-binary`)
- Network access to both the legacy MySQL database and the PostgreSQL target
  from the host running the script.

### Configuration

Provide connection details using DSNs or discrete environment variables:

- **MySQL (legacy source)**
  - `MYSQL_DSN` (e.g. `mysql://user:pass@legacy-host:3306/legacy_db`), **or**
  - `MYSQL_HOST` (default: `localhost`)
  - `MYSQL_PORT` (default: `3306`)
  - `MYSQL_NAME` (**required**)
  - `MYSQL_USER` (**required**)
  - `MYSQL_PASSWORD` (optional)
- **PostgreSQL (new target)**
  - `POSTGRES_DSN` (e.g. `postgresql://user:pass@new-host:5432/ctms`), **or**
  - `POSTGRES_HOST` / `DB_HOST` (default: `localhost`)
  - `POSTGRES_PORT` / `DB_PORT` (default: `5432`)
  - `POSTGRES_NAME` / `DB_NAME` (**required**)
  - `POSTGRES_USER` / `DB_USER` (**required**)
  - `POSTGRES_PASSWORD` / `DB_PASSWORD` (optional)

Additional optional tuning variables:

- `MIGRATION_BATCH_SIZE` — number of rows copied per transaction (default 500).
- `MIGRATION_LOG_LEVEL` — overrides the logging level (default `INFO`).

### Executing the Migration

1. Install dependencies (ideally within a virtual environment):

   ```bash
   pip install pymysql psycopg2-binary
   ```

2. Export the connection environment variables for both databases (example):

   ```bash
   export MYSQL_HOST=legacy-db.internal
   export MYSQL_NAME=legacy_auth
   export MYSQL_USER=legacy_admin
   export MYSQL_PASSWORD=legacy_secret

   export DB_HOST=postgres.internal
   export DB_PORT=5432
   export DB_NAME=ctms
   export DB_USER=postgres
   export DB_PASSWORD=secret
   ```

3. Run the migration module:

   ```bash
   python -m database.migrate_auth_data --batch-size 1000
   ```

   The script processes each `auth_*` table in dependency order, wrapping every
   batch in a PostgreSQL transaction. Skipped rows (due to unique collisions or
   existing primary keys) are emitted in the log for follow-up.

### Post-migration Validation

Administrators should confirm the data transfer before granting access:

1. Compare row counts for every migrated table:

   ```sql
   -- Run in PostgreSQL
   SELECT 'auth_user' AS table, COUNT(*) FROM auth_user
   UNION ALL
   SELECT 'auth_group', COUNT(*) FROM auth_group
   UNION ALL
   SELECT 'auth_permission', COUNT(*) FROM auth_permission
   UNION ALL
   SELECT 'auth_group_permissions', COUNT(*) FROM auth_group_permissions
   UNION ALL
   SELECT 'auth_user_groups', COUNT(*) FROM auth_user_groups
   UNION ALL
   SELECT 'auth_user_user_permissions', COUNT(*) FROM auth_user_user_permissions
   UNION ALL
   SELECT 'django_content_type', COUNT(*) FROM django_content_type;
   ```

2. Review the migration logs for any skipped records and resolve the reported
   conflicts (e.g., rename conflicting usernames in MySQL and rerun the
   migration for the affected tables).

3. Spot-check a few representative users or groups to ensure permissions and
   group memberships match the legacy environment.

 ## PostgreSQL Auth Schema Integration

 The Django authentication tables defined in `auth_tables_postgres.sql` use
 `GENERATED BY DEFAULT AS IDENTITY` columns so PostgreSQL manages the sequences
for primary keys without additional configuration. Each many-to-many join
table (`auth_group_permissions`, `auth_user_groups`, and
`auth_user_user_permissions`) enforces `UNIQUE` constraints on the related key
pairs and cascades deletions so removing a user, group, or permission clears its
association rows automatically. Likewise, `auth_permission.content_type_id`
references `django_content_type(id)` with `ON DELETE CASCADE`, ensuring orphaned
permissions are removed when a content type is dropped. Administrators should
run this script before any application tables that reference the auth schema so
foreign keys resolve correctly.

