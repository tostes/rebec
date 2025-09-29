# Database Administration Assets

This directory contains the assets required to provision and seed the
clinical trial administration database.

## Contents

- `sql/` — schema definition and seed data scripts executed in order by the
  bootstrapper:
  1. `vocabulary_tables.sql` — controlled vocabularies (countries,
     recruitment statuses, etc.).
  2. `clinical_trial_tables.sql` — core trial entities and relationships.
  3. `supporting_objects.sql` — triggers, helper functions, and stored
     procedures supporting the application.
  4. `vocabulary_seed.sql` — initial lookup data for the vocabulary tables.
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

