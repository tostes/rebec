"""Metadata and helpers for stored procedure deployment."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List

PROCEDURES_DIR = Path(__file__).resolve().parent
CONFIG_PATH = PROCEDURES_DIR / "procedures.json"


def load_config() -> List[Dict[str, Any]]:
    """Return a copy of the stored procedure metadata configuration."""
    if not CONFIG_PATH.exists():
        raise FileNotFoundError(
            f"Stored procedure configuration file missing: {CONFIG_PATH}"
        )

    with CONFIG_PATH.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    if not isinstance(data, list):
        raise ValueError("Stored procedure configuration must be a list of objects")

    return data


def save_config(entries: List[Dict[str, Any]]) -> None:
    """Persist stored procedure metadata back to disk."""
    CONFIG_PATH.write_text(
        json.dumps(entries, indent=2, sort_keys=False) + "\n", encoding="utf-8"
    )


STORED_PROCEDURES: List[Dict[str, Any]] = load_config()
"""Loaded stored procedure metadata for consumers that prefer module-level access."""
