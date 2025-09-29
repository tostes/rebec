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

The database has been carefully designed in **PostgreSQL**, with separate sections for:

- **Vocabulary tables** (countries, interventions, institutions, study phases, etc.)
- **Core clinical trial tables** (trial metadata, contacts, sponsors, interventions, outcomes, results, etc.)
- **Supporting objects**: functions, triggers, stored procedures

A dedicated area in the repository will contain:
- **DDL scripts** for all tables
- **Initial inserts** (vocabulary population)
- **Procedures and triggers**
- **Python script** to bootstrap the initial database (create + seed vocabulary)

---

## 📂 Repository Structure

*(em construção)*

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

After setting the database environment variables, apply the remaining Django core migrations
(sessions, admin, messages, etc.) normally:

```bash
cd backend
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
