"""Admin site customizations for the backend project."""

from __future__ import annotations

from django.contrib import admin

BRANDING_TEXT = "Rebec"


def apply_admin_branding() -> None:
    """Apply consistent branding to the Django admin site."""

    admin.site.site_header = BRANDING_TEXT
    admin.site.site_title = BRANDING_TEXT
    admin.site.index_title = BRANDING_TEXT
