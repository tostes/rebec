"""Metadata helpers for schema SQL assets."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List

SQL_DIR = Path(__file__).resolve().parent
CATALOG_PATH = SQL_DIR / "tables.json"


def load_table_catalog() -> List[Dict[str, Any]]:
    """Load the table catalog metadata."""
    if not CATALOG_PATH.exists():
        raise FileNotFoundError(
            f"Table catalog configuration file missing: {CATALOG_PATH}"
        )

    with CATALOG_PATH.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    if not isinstance(data, list):
        raise ValueError("Table catalog configuration must be a list of objects")

    return data


def save_table_catalog(entries: List[Dict[str, Any]]) -> None:
    """Persist table catalog metadata back to disk."""
    CATALOG_PATH.write_text(
        json.dumps(entries, indent=2, sort_keys=False) + "\n", encoding="utf-8"
    )


TABLE_CATALOG: List[Dict[str, Any]] = load_table_catalog()
"""Loaded table metadata for consumers that prefer module-level access."""
