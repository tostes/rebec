# Clinical Trials Registration Platform

This project aims to develop a modern and transparent platform for the registration, review, and publication of clinical trials.

The platform is inspired by the Brazilian Clinical Trials Registry (ReBEC) and is designed to ensure compliance, data quality, and usability for both researchers and reviewers.

---

## 🚀 Project Overview

The workflow of the clinical trials registry is as follows:

1. **Registrant** (logged-in user) fills out an extensive form with all required information about the clinical trial.
2. Once completed, the trial is **submitted for review**. While under review, no changes can be made by the registrant.
3. A **Reviewer** (different logged-in user) checks the submitted information and creates **observations** if there are errors or missing data.
4. - If there are pending issues, the reviewer sends the trial back to the registrant for corrections.
   - If there are no pending issues, the trial is **approved**, receives a **unique registration number**, and becomes publicly available on the platform.

---

## 🛠️ Tech Stack

- **Backend:** PostgreSQL with PostgresREST (custom REST API)
- **Framework:** Django (only for `auth_user` authentication and session management)
- **Language:** Python
- **Frontend:** To be defined (focus on admin-friendly UI)

---

## 📑 Database Structure

The PostgreSQL assets that ship with the project live under `database/`:

- `database/sql/vocabulary_tables.sql` defines reference data such as
  `vocabulary_country`, `vocabulary_recruitment_status`,
  `vocabulary_intervention_type`, `vocabulary_study_phase`, and
  `vocabulary_condition_category`.
- `database/sql/clinical_trial_tables.sql` provisions the core `ct`
  relations, including `trials`, `research_institutions`,
  `trial_countries`, `interventions`, `trial_conditions`,
  `trial_documents`, status history tracking, and related sponsor lookups.
- `database/sql/supporting_objects.sql` adds cross-cutting helpers (e.g. the
  `set_updated_at` trigger) that keep timestamps current.
- `database/sql/vocabulary_seed.sql` pre-populates controlled vocabularies for
  immediate use after provisioning.
- `database/sql/auth_tables_postgres.sql` mirrors the authentication tables used
  by Django so the backend can authenticate against PostgreSQL.
- `database/stored_procedures/` contains the stored procedure catalog governed
  by `procedures.json`. Each entry points at SQL source files such as
  `get_or_create_sponsor.sql` and `create_trial.sql` that are deployed during
  bootstrapping.
- `database/bootstrap.py` is the Python entry point that orchestrates schema
  creation, stored procedure deployment, and seed loading.

### Bootstrap workflow

Administrators can provision a PostgreSQL instance end-to-end without inspecting
individual scripts:

1. Provide connection details via either `DATABASE_URL` **or** the component
   variables `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, and `DB_PASSWORD`.
2. Run the automated bootstrap: `python -m database.bootstrap`.
3. The script applies the schema files in dependency order, deploys the
   procedures declared in `database/stored_procedures/procedures.json`, and
   finally loads the seed data from `database/sql/vocabulary_seed.sql`.
   Objects whose definitions already match the repository are detected via
   `pg_catalog` and skipped with a log message so reruns remain idempotent.

### Key schema components

- **Vocabulary tables:** `vocabulary_country`,
  `vocabulary_recruitment_status`, `vocabulary_intervention_type`,
  `vocabulary_study_phase`, `vocabulary_condition_category`.
- **Core `ct_*` tables:** `trials`, `trial_countries`, `trial_conditions`,
  `trial_documents`, `interventions`, and supporting `sponsors` relations.
- **Supporting functions and procedures:** `set_updated_at` trigger function,
  `get_or_create_sponsor()` lookup helper, and the `create_trial` procedure that
  wraps trial insertion logic.

---

## 📂 Repository Structure

- `backend/` — Django project that layers session and admin capabilities on top
  of the shared PostgreSQL schema.
- `database/` — SQL definitions, stored procedure catalog, and bootstrap
  automation for the clinical trials data model.
- `docs/` — Reference guides for administrators, including legacy
  authentication integration instructions.
- `requirements.txt` — Python dependencies shared by the backend and database
  tooling.

---

## 🧭 Django Backend Setup

The repository now includes a lightweight Django project in `backend/` that provides session
management and admin capabilities on top of the shared PostgreSQL schema.

### Database configuration

`backend/backend/settings.py` reads the PostgreSQL connection details from the environment:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=ctms
export DB_USER=postgres
export DB_PASSWORD=secret
```

Point these variables at the database that has been provisioned with the SQL assets under
`database/sql/` (particularly `database/sql/auth_tables_postgres.sql`). The Django project
authenticates directly against the existing `auth_*` tables that were created by those scripts.

### Running Django migrations without touching `auth_*`

The project ships with a database router (`backend/backend/dbrouters.py`) that prevents Django
from managing migrations for the `auth` and `contenttypes` applications. This allows the framework
to read/write the shared tables while leaving their schema under manual control.

After setting the database environment variables, install the Python dependencies and apply the
remaining Django core migrations (sessions, admin, messages, etc.) normally:

```bash
cd backend
pip install -r ../requirements.txt
python manage.py migrate --noinput
```

Because of the router, the migrate command will skip any schema changes for the shared `auth_*`
tables while still recording their migration state. You can now start the Django admin and
authenticate users with the credentials stored in those existing tables.

---

## 🔒 Integração com autenticação MySQL legada

- Consulte o guia [docs/mysql-auth-integration.md](docs/mysql-auth-integration.md) para alinhar o esquema `auth_*` com o esperado pelo Django e configurar múltiplos bancos.
- Resumo para administradores:
  1. Fazer backup do schema/tabelas `auth_*` no MySQL legado.
  2. Executar o script [`database/sql/mysql_auth_alignment.sql`](database/sql/mysql_auth_alignment.sql) para ajustar tipos, collation e chaves estrangeiras.
  3. Configurar o Django com a conexão adicional `legacy_auth` e o roteador descritos no guia.
  4. Testar logins e replicação antes de liberar para produção.
