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
import re
from datetime import date
from pathlib import Path
from typing import Iterable, List, Optional, Tuple

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


CREATE_OBJECT_RE = re.compile(
    r"^CREATE\s+(OR\s+REPLACE\s+)?"
    r"(?P<type>TABLE|VIEW|MATERIALIZED\s+VIEW|FUNCTION|PROCEDURE)"
    r"\s+(IF\s+NOT\s+EXISTS\s+)?(?P<name>[\w\.\"']+)",
    re.IGNORECASE | re.DOTALL,
)


def _split_statements(sql: str) -> List[str]:
    statements: List[str] = []
    current: List[str] = []
    in_single = False
    in_double = False
    dollar_tag: Optional[str] = None
    i = 0
    while i < len(sql):
        ch = sql[i]
        if dollar_tag:
            if sql.startswith(dollar_tag, i):
                current.append(dollar_tag)
                i += len(dollar_tag)
                dollar_tag = None
                continue
            current.append(ch)
            i += 1
            continue

        if ch == "'" and not in_double:
            in_single = not in_single
            current.append(ch)
            i += 1
            continue
        if ch == '"' and not in_single:
            in_double = not in_double
            current.append(ch)
            i += 1
            continue
        if ch == "$" and not in_single and not in_double:
            end = i + 1
            while end < len(sql) and (sql[end].isalnum() or sql[end] == "_"):
                end += 1
            if end < len(sql) and sql[end] == "$":
                tag = sql[i : end + 1]
                dollar_tag = tag
                current.append(tag)
                i = end + 1
                continue
        if ch == ";" and not in_single and not in_double:
            statement = "".join(current).strip()
            if statement:
                statements.append(statement)
            current = []
            i += 1
            continue
        current.append(ch)
        i += 1

    tail = "".join(current).strip()
    if tail:
        statements.append(tail)
    return statements


def _normalize_sql(sql: str) -> str:
    cleaned = re.sub(r"--.*", "", sql)
    cleaned = re.sub(r"/\*.*?\*/", "", cleaned, flags=re.DOTALL)
    cleaned = cleaned.strip().rstrip(";")
    cleaned = re.sub(r"\s+", " ", cleaned)
    cleaned = re.sub(r"\bpublic\.", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\bCREATE\s+OR\s+REPLACE\b", "CREATE", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\bIF\s+NOT\s+EXISTS\b", "", cleaned, flags=re.IGNORECASE)
    return cleaned.strip().lower()


def _schema_and_name(identifier: str) -> Tuple[Optional[str], str]:
    identifier = identifier.strip()
    if identifier.startswith("\"") and identifier.endswith("\""):
        identifier = identifier[1:-1]
    if "." in identifier:
        schema, name = identifier.split(".", 1)
        return schema.strip('"'), name.strip('"')
    return None, identifier.strip('"')


_HAS_PG_GET_TABLEDEF: Optional[bool] = None


def _ensure_pg_get_tabledef(cursor) -> bool:
    global _HAS_PG_GET_TABLEDEF
    if _HAS_PG_GET_TABLEDEF is not None:
        return _HAS_PG_GET_TABLEDEF
    cursor.execute(
        "SELECT EXISTS ("
        "    SELECT 1"
        "    FROM pg_proc p"
        "    JOIN pg_namespace n ON n.oid = p.pronamespace"
        "    WHERE n.nspname = 'pg_catalog'"
        "      AND p.proname = 'pg_get_tabledef'"
        ")"
    )
    _HAS_PG_GET_TABLEDEF = bool(cursor.fetchone()[0])
    return _HAS_PG_GET_TABLEDEF


def _existing_ddl(cursor, object_type: str, identifier: str, args: Optional[str]) -> Optional[str]:
    object_type = object_type.upper()
    if object_type in {"TABLE", "MATERIALIZED VIEW", "VIEW"}:
        cursor.execute("SELECT to_regclass(%s)", (identifier,))
        result = cursor.fetchone()
        if not result or result[0] is None:
            return None
        regclass = str(result[0])
        if object_type == "TABLE":
            if not _ensure_pg_get_tabledef(cursor):
                return None
            cursor.execute("SELECT pg_get_tabledef(%s::regclass)", (regclass,))
        elif object_type == "MATERIALIZED VIEW":
            cursor.execute(
                "SELECT 'CREATE MATERIALIZED VIEW ' || %s::regclass || ' AS ' || pg_get_viewdef(%s::regclass, true)",
                (regclass, regclass),
            )
        else:
            cursor.execute(
                "SELECT 'CREATE VIEW ' || %s::regclass || ' AS ' || pg_get_viewdef(%s::regclass, true)",
                (regclass, regclass),
            )
        row = cursor.fetchone()
        return row[0] if row else None

    if object_type in {"FUNCTION", "PROCEDURE"}:
        schema, name = _schema_and_name(identifier)
        prokind = "f" if object_type == "FUNCTION" else "p"
        params = [name]
        query = [
            "SELECT pg_get_functiondef(p.oid)",
            "FROM pg_proc p",
            "JOIN pg_namespace n ON n.oid = p.pronamespace",
            "WHERE p.proname = %s",
            "AND p.prokind = %s",
        ]
        params.append(prokind)
        if schema:
            query.append("AND n.nspname = %s")
            params.append(schema)
        if args is not None:
            normalized_args = _normalize_function_args(args)
            if normalized_args is not None:
                query.append("AND pg_get_function_identity_arguments(p.oid) = %s")
                params.append(normalized_args)
        query.append("LIMIT 2")
        cursor.execute("\n".join(query), params)
        rows = cursor.fetchall()
        if len(rows) != 1:
            return None
        return rows[0][0]

    return None


def _normalize_function_args(args: str) -> Optional[str]:
    if args is None:
        return None
    args = args.strip()
    if not args:
        return ""
    parts = []
    for raw in args.split(","):
        token = raw.strip()
        if not token:
            continue
        token = token.split("=")[0].strip()
        words = token.split()
        cleaned: List[str] = []
        for word in words:
            upper = word.upper()
            if upper in {"IN", "OUT", "INOUT", "VARIADIC"}:
                continue
            cleaned.append(word)
        if not cleaned:
            return None
        # assume last elements describe the type possibly multi-word
        # drop parameter name if more than one token
        if len(cleaned) > 1:
            type_tokens = cleaned[1:]
        else:
            type_tokens = cleaned
        parts.append(" ".join(type_tokens))
    return ", ".join(parts)


def _identify_object(statement: str) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    match = CREATE_OBJECT_RE.match(statement.lstrip())
    if not match:
        return None, None, None
    object_type = match.group("type").upper().replace("  ", " ")
    name = match.group("name")
    args = None
    if object_type in {"FUNCTION", "PROCEDURE"}:
        signature_match = re.search(r"\bFUNCTION\s+[^\s(]+\s*\((.*?)\)", statement, re.IGNORECASE | re.DOTALL)
        if object_type == "PROCEDURE":
            signature_match = re.search(r"\bPROCEDURE\s+[^\s(]+\s*\((.*?)\)", statement, re.IGNORECASE | re.DOTALL)
        if signature_match:
            args = signature_match.group(1)
    return object_type, name, args


def _definitions_equal(file_sql: str, database_sql: Optional[str]) -> bool:
    if database_sql is None:
        return False
    return _normalize_sql(file_sql) == _normalize_sql(database_sql)


def execute_file(cursor, path: Path) -> bool:
    with path.open("r", encoding="utf-8") as handle:
        sql = handle.read()

    statements = _split_statements(sql)
    relative_path = path.relative_to(BASE_DIR)
    print(f"Inspecting {relative_path} for changes ...")

    executed_any = False
    for statement in statements:
        object_type, name, args = _identify_object(statement)
        if object_type and name:
            existing = _existing_ddl(cursor, object_type, name, args)
            if _definitions_equal(statement, existing):
                print(
                    f"  Skipping {object_type} {name}: no changes detected."
                )
                continue
        cursor.execute(statement)
        executed_any = True
        if object_type and name:
            print(f"  Applied {object_type} {name}.")
    if not executed_any:
        print(f"  No changes required for {relative_path}.")

    return executed_any


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

        applied = execute_file(cursor, sql_path)
        entry["updated"] = True
        if applied:
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

