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

## 🔒 Integração com autenticação MySQL legada

- Consulte o guia [docs/mysql-auth-integration.md](docs/mysql-auth-integration.md) para alinhar o esquema `auth_*` com o esperado pelo Django e configurar múltiplos bancos.
- Resumo para administradores:
  1. Fazer backup do schema/tabelas `auth_*` no MySQL legado.
  2. Executar o script [`database/sql/mysql_auth_alignment.sql`](database/sql/mysql_auth_alignment.sql) para ajustar tipos, collation e chaves estrangeiras.
  3. Configurar o Django com a conexão adicional `legacy_auth` e o roteador descritos no guia.
  4. Testar logins e replicação antes de liberar para produção.
