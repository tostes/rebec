"""Bootstrap clinical trial administration database schema and seed data.

The script expects access to a PostgreSQL database via either:

* ``DATABASE_URL``: a libpq connection string / DSN (e.g. ``postgresql://user:pass@localhost:5432/ctms``)
* or the component environment variables ``DB_HOST`` (default ``localhost``), ``DB_PORT`` (default ``5432``),
  ``DB_NAME`` (required), ``DB_USER`` (required), and optional ``DB_PASSWORD``.

Example usage::

    export DB_HOST=localhost
    export DB_PORT=5432
    export DB_NAME=ctms
    export DB_USER=postgres
    export DB_PASSWORD=secret
    python -m database.bootstrap

The script executes all SQL files in ``database/sql`` in a deterministic order and
wraps the process in a transaction. Seed data is loaded after the schema and
supporting objects are created.
"""

from __future__ import annotations

import os
from datetime import date
from pathlib import Path
from typing import Iterable, List

import psycopg2

from database.stored_procedures.config import load_config, save_config

BASE_DIR = Path(__file__).resolve().parent
SQL_DIR = BASE_DIR / "sql"
STORED_PROCEDURES_DIR = BASE_DIR / "stored_procedures"

SCHEMA_FILES = [
    "vocabulary_tables.sql",
    "auth_tables_postgres.sql",
    "clinical_trial_tables.sql",
    "supporting_objects.sql",
    "vocabulary_seed.sql",
]


def build_dsn() -> str:
    """Construct a libpq connection string from environment variables."""
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return database_url

    missing: List[str] = []
    db_name = os.getenv("DB_NAME")
    if not db_name:
        missing.append("DB_NAME")
    db_user = os.getenv("DB_USER")
    if not db_user:
        missing.append("DB_USER")

    if missing:
        raise RuntimeError(
            "Missing required environment variables for database connection: "
            + ", ".join(missing)
        )

    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "5432")
    db_password = os.getenv("DB_PASSWORD")

    dsn_parts = [
        f"host={db_host}",
        f"port={db_port}",
        f"dbname={db_name}",
        f"user={db_user}",
    ]

    if db_password:
        dsn_parts.append(f"password={db_password}")

    return " ".join(dsn_parts)


def iter_sql_files(filenames: Iterable[str]) -> Iterable[Path]:
    for name in filenames:
        path = SQL_DIR / name
        if not path.exists():
            raise FileNotFoundError(f"Expected SQL file missing: {path}")
        yield path


def execute_file(cursor, path: Path) -> None:
    with path.open("r", encoding="utf-8") as handle:
        sql = handle.read()
    print(f"Applying {path.relative_to(BASE_DIR)} ...")
    cursor.execute(sql)


def deploy_stored_procedures(cursor) -> None:
    metadata = load_config()
    modified = False

    for entry in metadata:
        if entry.get("updated"):
            continue

        filename = entry.get("filename")
        if not filename:
            raise ValueError(
                f"Stored procedure metadata for {entry.get('name', '<unknown>')} is missing a filename."
            )

        sql_path = STORED_PROCEDURES_DIR / filename
        if not sql_path.exists():
            raise FileNotFoundError(
                f"Stored procedure SQL file missing: {sql_path}"
            )

        execute_file(cursor, sql_path)
        entry["updated"] = True
        entry["date_update"] = date.today().isoformat()
        modified = True

    if modified:
        save_config(metadata)


def main() -> None:
    dsn = build_dsn()
    print("Connecting to PostgreSQL with DSN:", dsn)
    with psycopg2.connect(dsn) as connection:
        connection.autocommit = False
        with connection.cursor() as cursor:
            for sql_file in iter_sql_files(SCHEMA_FILES):
                execute_file(cursor, sql_file)
            deploy_stored_procedures(cursor)
        connection.commit()
    print("Bootstrap completed successfully.")


if __name__ == "__main__":
    main()

