from __future__ import annotations

from django import template

register = template.Library()


@register.filter
def dict_get(value: dict, key: str):
    """Retrieve the value for a key from a dict safely for table rendering."""
    if isinstance(value, dict):
        return value.get(key, "")
    return ""
