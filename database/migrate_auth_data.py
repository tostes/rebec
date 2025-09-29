"""Utility to migrate Django auth data from legacy MySQL to PostgreSQL.

The migration can now work with either an explicit list of source columns or a
set of columns to ignore for each table, ensuring inserts only reference fields
that exist in the target schema.
"""
from __future__ import annotations

import argparse
import logging
import os
from dataclasses import dataclass
from typing import Dict, List, Optional, Sequence, Tuple
from urllib.parse import unquote, urlparse

import pymysql
import psycopg2
import psycopg2.extras
from psycopg2 import sql


LOGGER = logging.getLogger(__name__)


@dataclass(frozen=True)
class TableSpec:
    """Describes migration hints for a single auth table."""

    name: str
    pk: str = "id"
    unique_checks: Sequence[Sequence[str]] = ()
    boolean_columns: Sequence[str] = ()
    columns: Optional[Sequence[str]] = None
    ignore_columns: Sequence[str] = ()


TABLE_SPECS: Sequence[TableSpec] = (
    TableSpec(
        "django_content_type",
        unique_checks=(("app_label", "model"),),
        columns=("id", "app_label", "model"),
    ),
    TableSpec(
        "auth_permission",
        unique_checks=(("content_type_id", "codename"),),
        columns=("id", "name", "content_type_id", "codename"),
    ),
    TableSpec("auth_group", unique_checks=(("name",),), columns=("id", "name")),
    TableSpec(
        "auth_user",
        unique_checks=(("username",),),
        boolean_columns=("is_superuser", "is_staff", "is_active"),
    ),
    TableSpec("auth_group_permissions", unique_checks=(("group_id", "permission_id"),)),
    TableSpec("auth_user_groups", unique_checks=(("user_id", "group_id"),)),
    TableSpec("auth_user_user_permissions", unique_checks=(("user_id", "permission_id"),)),
)


@dataclass
class SkippedRecord:
    """Represents a row that was skipped during the migration."""

    table: str
    reason: str
    details: Dict[str, object]

    def as_message(self) -> str:
        parts = [f"{column}={value!r}" for column, value in self.details.items()]
        details = ", ".join(parts)
        return f"{self.table}: {self.reason} ({details})"


class MigrationError(Exception):
    """Raised when required connection details are missing."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Copy Django auth_* data from a legacy MySQL database into the new "
            "PostgreSQL schema while preserving primary keys and relationships."
        )
    )
    parser.add_argument(
        "--mysql-dsn",
        help=(
            "MySQL connection string (e.g. mysql://user:pass@localhost:3306/legacy_db). "
            "Overrides MYSQL_DSN if provided."
        ),
    )
    parser.add_argument(
        "--postgres-dsn",
        help=(
            "PostgreSQL connection string (e.g. postgresql://user:pass@localhost:5432/ctms). "
            "Overrides POSTGRES_DSN if provided."
        ),
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=int(os.environ.get("MIGRATION_BATCH_SIZE", 500)),
        help="Number of rows to transfer per transaction (default: 500).",
    )
    parser.add_argument(
        "--log-level",
        default=os.environ.get("MIGRATION_LOG_LEVEL", "INFO"),
        help="Logging level (default: INFO).",
    )
    return parser.parse_args()


def _connection_kwargs_from_env(prefix: str, defaults: Optional[Dict[str, object]] = None) -> Dict[str, object]:
    defaults = defaults or {}
    return {
        "host": os.environ.get(f"{prefix}_HOST", defaults.get("host", "localhost")),
        "port": int(os.environ.get(f"{prefix}_PORT", defaults.get("port", 0)) or defaults.get("port", 0)),
        "user": os.environ.get(f"{prefix}_USER", defaults.get("user")),
        "password": os.environ.get(f"{prefix}_PASSWORD", defaults.get("password")),
        "database": os.environ.get(f"{prefix}_NAME", defaults.get("database")),
    }


def _parse_dsn(dsn: str, default_port: int) -> Dict[str, object]:
    url = urlparse(dsn)
    if not url.scheme:
        raise MigrationError(f"Invalid DSN '{dsn}'.")
    return {
        "host": url.hostname or "localhost",
        "port": url.port or default_port,
        "user": unquote(url.username) if url.username else None,
        "password": unquote(url.password) if url.password else None,
        "database": url.path.lstrip("/") if url.path else None,
    }


def mysql_connection_kwargs(dsn: Optional[str]) -> Dict[str, object]:
    params = _connection_kwargs_from_env("MYSQL", {"port": 3306})
    if dsn:
        params.update(_parse_dsn(dsn, 3306))
    elif os.environ.get("MYSQL_DSN"):
        params.update(_parse_dsn(os.environ["MYSQL_DSN"], 3306))
    if not params.get("database"):
        raise MigrationError("MySQL database name must be provided via DSN or MYSQL_NAME.")
    if not params.get("user"):
        raise MigrationError("MySQL user must be provided via DSN or MYSQL_USER.")
    return params


def postgres_connection_kwargs(dsn: Optional[str]) -> Dict[str, object]:
    params = _connection_kwargs_from_env("POSTGRES", {"port": 5432})
    # Support reuse of the bootstrap environment variables.
    params["host"] = os.environ.get("DB_HOST", params.get("host", "localhost"))
    params["port"] = int(os.environ.get("DB_PORT", params.get("port", 5432)) or 5432)
    params["user"] = os.environ.get("DB_USER", params.get("user"))
    params["password"] = os.environ.get("DB_PASSWORD", params.get("password"))
    params["database"] = os.environ.get("DB_NAME", params.get("database"))
    if dsn:
        params.update(_parse_dsn(dsn, 5432))
    elif os.environ.get("POSTGRES_DSN"):
        params.update(_parse_dsn(os.environ["POSTGRES_DSN"], 5432))
    if not params.get("database"):
        raise MigrationError(
            "PostgreSQL database name must be provided via DSN or POSTGRES_NAME/DB_NAME."
        )
    if not params.get("user"):
        raise MigrationError("PostgreSQL user must be provided via DSN or POSTGRES_USER/DB_USER.")
    return params


def open_mysql_connection(params: Dict[str, object]) -> pymysql.connections.Connection:
    LOGGER.debug("Connecting to MySQL at %s:%s", params["host"], params["port"])
    return pymysql.connect(
        host=params["host"],
        port=int(params["port"] or 3306),
        user=params["user"],
        password=params.get("password"),
        database=params["database"],
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
    )


def open_postgres_connection(params: Dict[str, object]) -> psycopg2.extensions.connection:
    LOGGER.debug("Connecting to PostgreSQL at %s:%s", params["host"], params["port"])
    return psycopg2.connect(
        host=params["host"],
        port=int(params["port"] or 5432),
        user=params["user"],
        password=params.get("password"),
        dbname=params["database"],
    )


def _convert_booleans(row: Dict[str, object], boolean_columns: Sequence[str]) -> None:
    for column in boolean_columns:
        if column in row and row[column] is not None:
            value = row[column]
            if isinstance(value, bool):
                row[column] = value
            elif isinstance(value, (int, float)):
                row[column] = bool(value)
            elif isinstance(value, str):
                row[column] = value.strip().lower() in {"1", "t", "true", "y", "yes"}
            else:
                row[column] = bool(value)


def _check_conflicts(
    pg_cursor: psycopg2.extensions.cursor,
    table: TableSpec,
    row: Dict[str, object],
) -> Optional[SkippedRecord]:
    pk_value = row.get(table.pk)
    if pk_value is not None:
        pg_cursor.execute(
            f"SELECT 1 FROM {table.name} WHERE {table.pk} = %s",
            (pk_value,),
        )
        if pg_cursor.fetchone():
            return SkippedRecord(
                table=table.name,
                reason=f"primary key {table.pk} collision",
                details={table.pk: pk_value},
            )
    for constraint in table.unique_checks:
        values = [row.get(column) for column in constraint]
        if all(value is None for value in values):
            continue
        where_clause = " AND ".join(f"{column} = %s" for column in constraint)
        pg_cursor.execute(
            f"SELECT {table.pk} FROM {table.name} WHERE {where_clause}",
            values,
        )
        existing = pg_cursor.fetchone()
        if existing:
            details = {column: row.get(column) for column in constraint}
            details[table.pk] = existing[0]
            return SkippedRecord(
                table=table.name,
                reason="unique constraint conflict",
                details=details,
            )
    return None


def _reset_identity(pg_cursor: psycopg2.extensions.cursor, table: TableSpec) -> None:
    pg_cursor.execute("SELECT pg_get_serial_sequence(%s, %s)", (table.name, table.pk))
    sequence_row = pg_cursor.fetchone()
    if not sequence_row:
        return
    sequence_name = sequence_row[0]
    if not sequence_name:
        return
    query = sql.SQL(
        "SELECT setval(%s, COALESCE((SELECT MAX({pk}) FROM {table}), 1), true)"
    ).format(pk=sql.Identifier(table.pk), table=sql.Identifier(table.name))
    pg_cursor.execute(query, (sequence_name,))


def _get_postgres_columns(
    pg_cursor: psycopg2.extensions.cursor, table_name: str
) -> List[str]:
    pg_cursor.execute(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name = %s
        ORDER BY ordinal_position
        """,
        (table_name,),
    )
    return [row[0] for row in pg_cursor.fetchall()]


def migrate_table(
    mysql_conn: pymysql.connections.Connection,
    pg_conn: psycopg2.extensions.connection,
    table: TableSpec,
    batch_size: int,
    skipped: List[SkippedRecord],
) -> None:
    LOGGER.info("Migrating table %s", table.name)
    inserted = 0
    with pg_conn.cursor() as pg_cursor:
        destination_columns = _get_postgres_columns(pg_cursor, table.name)
    destination_column_set = set(destination_columns)
    with mysql_conn.cursor() as mysql_cursor:
        select_clause = (
            ", ".join(table.columns) if table.columns else "*"
        )
        mysql_cursor.execute(
            f"SELECT {select_clause} FROM {table.name} ORDER BY {table.pk}"
        )
        source_columns = [desc[0] for desc in mysql_cursor.description]
        source_column_set = set(source_columns)
        ignore_set = set(table.ignore_columns)
        preferred_order = list(table.columns) if table.columns else list(destination_columns)
        if not preferred_order:
            preferred_order = source_columns
        column_order = [
            column
            for column in preferred_order
            if column in destination_column_set
            and column in source_column_set
            and column not in ignore_set
        ]
        if not column_order:
            raise MigrationError(
                f"No common columns found for table {table.name}."
            )
        while True:
            rows = mysql_cursor.fetchmany(batch_size)
            if not rows:
                break
            pg_cursor = pg_conn.cursor()
            try:
                to_insert: List[Tuple[object, ...]] = []
                for row in rows:
                    _convert_booleans(row, table.boolean_columns)
                    conflict = _check_conflicts(pg_cursor, table, row)
                    if conflict:
                        skipped.append(conflict)
                        LOGGER.warning("Skipping row: %s", conflict.as_message())
                        continue
                    values = tuple(row.get(column) for column in column_order)
                    to_insert.append(values)
                if to_insert:
                    psycopg2.extras.execute_values(
                        pg_cursor,
                        f"INSERT INTO {table.name} ({', '.join(column_order)}) VALUES %s",
                        to_insert,
                    )
                    inserted += len(to_insert)
                pg_conn.commit()
            except Exception:
                pg_conn.rollback()
                raise
            finally:
                pg_cursor.close()
            LOGGER.debug("Processed batch of %d rows from %s", len(rows), table.name)
    pg_cursor = pg_conn.cursor()
    try:
        _reset_identity(pg_cursor, table)
        pg_conn.commit()
    except Exception:
        pg_conn.rollback()
        raise
    finally:
        pg_cursor.close()
    LOGGER.info("Inserted %d rows into %s", inserted, table.name)


def main() -> None:
    args = parse_args()
    logging.basicConfig(level=args.log_level.upper(), format="%(levelname)s: %(message)s")
    try:
        mysql_params = mysql_connection_kwargs(args.mysql_dsn)
        postgres_params = postgres_connection_kwargs(args.postgres_dsn)
    except MigrationError as exc:
        LOGGER.error(str(exc))
        raise SystemExit(2) from exc

    LOGGER.debug("MySQL connection parameters resolved to: %s", mysql_params)
    LOGGER.debug("PostgreSQL connection parameters resolved to: %s", postgres_params)

    skipped: List[SkippedRecord] = []
    with open_mysql_connection(mysql_params) as mysql_conn, open_postgres_connection(
        postgres_params
    ) as pg_conn:
        pg_conn.autocommit = False
        for table in TABLE_SPECS:
            migrate_table(mysql_conn, pg_conn, table, args.batch_size, skipped)

    if skipped:
        LOGGER.warning("%d records were skipped during migration:", len(skipped))
        for record in skipped:
            LOGGER.warning(" - %s", record.as_message())
    else:
        LOGGER.info("Migration completed without skipped records.")


if __name__ == "__main__":
    main()
