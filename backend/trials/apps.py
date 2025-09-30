from django.apps import AppConfig


class TrialsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "trials"
    verbose_name = "Trials"

    def ready(self) -> None:  # pragma: no cover - configuration
        from backend.admin import apply_admin_branding

        apply_admin_branding()
