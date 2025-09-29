"""Database router configuration for shared authentication tables."""

from __future__ import annotations

from typing import Optional


class AuthRouter:
    """Prevent Django from managing the shared auth and content type tables."""

    route_app_labels = {"auth", "contenttypes"}

    def db_for_read(self, model, **hints):  # type: ignore[override]
        if model._meta.app_label in self.route_app_labels:
            return "default"
        return None

    def db_for_write(self, model, **hints):  # type: ignore[override]
        if model._meta.app_label in self.route_app_labels:
            return "default"
        return None

    def allow_relation(self, obj1, obj2, **hints):  # type: ignore[override]
        if {
            obj1._meta.app_label,
            obj2._meta.app_label,
        } & self.route_app_labels:
            return True
        return None

    def allow_migrate(
        self,
        db: str,
        app_label: str,
        model_name: Optional[str] = None,
        **hints,
    ) -> Optional[bool]:  # type: ignore[override]
        if app_label in self.route_app_labels:
            return False
        return None
