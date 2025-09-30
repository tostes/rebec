from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import date, datetime
from typing import Any, Iterable, Optional

from django.db import connection
from django.views.generic import TemplateView
from django.utils.formats import date_format
from django.utils.html import format_html, format_html_join
from django.utils.text import slugify


@dataclass(frozen=True)
class TrialColumn:
    key: str
    label: str


class TrialListView(TemplateView):
    template_name = "admin/trials_list.html"
    columns: tuple[TrialColumn, ...] = (
        TrialColumn("public_identifier", "Public ID"),
        TrialColumn("official_title", "Official Title"),
        TrialColumn("lead_sponsor", "Lead Sponsor"),
        TrialColumn("recruitment_status", "Recruitment Status"),
        TrialColumn("study_phase", "Study Phase"),
        TrialColumn("countries", "Countries"),
        TrialColumn("primary_completion_date", "Primary Completion"),
        TrialColumn("updated_at", "Last Updated"),
    )

    def get_context_data(self, **kwargs: Any) -> dict[str, Any]:
        context = super().get_context_data(**kwargs)
        trials: list[dict[str, Any]] = []
        load_error = False
        try:
            payload = self._call_list_trials()
        except Exception:  # pragma: no cover - defensive; logging could be added later
            payload = []
            load_error = True

        if isinstance(payload, list):
            raw_trials: Iterable[dict[str, Any]] = [
                item for item in payload if isinstance(item, dict)
            ]
        elif isinstance(payload, dict):
            raw_trials = [payload]
        else:
            raw_trials = []

        trials = [self._transform_trial(trial) for trial in raw_trials]

        context.update({
            "trials": trials,
            "columns": self.columns,
            "load_error": load_error,
        })
        return context

    def _call_list_trials(self) -> Any:
        with connection.cursor() as cursor:
            cursor.callproc("list_trials")
            row = cursor.fetchone()
        if not row:
            return []
        raw_payload = row[0]
        if isinstance(raw_payload, str):
            try:
                return json.loads(raw_payload)
            except json.JSONDecodeError:
                return []
        return raw_payload

    def _transform_trial(self, trial: dict[str, Any]) -> dict[str, Any]:
        return {
            "public_identifier": self._clean_text(trial.get("public_identifier")),
            "official_title": self._clean_text(trial.get("official_title")),
            "lead_sponsor": self._format_lead_sponsor(trial.get("lead_sponsor")),
            "recruitment_status": self._format_recruitment_status(
                trial.get("recruitment_status")
            ),
            "study_phase": self._format_study_phase(trial.get("study_phase")),
            "countries": self._format_countries(trial.get("countries")),
            "primary_completion_date": self._format_date(
                trial.get("primary_completion_date")
            ),
            "updated_at": self._format_date(trial.get("updated_at")),
        }

    def _clean_text(self, value: Any) -> str:
        if value is None:
            return ""
        return str(value)

    def _format_lead_sponsor(self, sponsor: Any) -> str:
        if not isinstance(sponsor, dict):
            return ""
        name = sponsor.get("name")
        sponsor_type = sponsor.get("sponsor_type")
        if name and sponsor_type:
            return f"{name} ({sponsor_type})"
        if name:
            return str(name)
        return ""

    def _format_recruitment_status(self, status: Any) -> str:
        if not isinstance(status, dict):
            return ""
        code = status.get("code")
        label = status.get("description") or code
        if not label:
            return ""
        css_modifier = slugify(code or label) or "default"
        return format_html(
            '<span class="status status-{}">{}</span>',
            css_modifier,
            label,
        )

    def _format_study_phase(self, phase: Any) -> str:
        if not isinstance(phase, dict):
            return ""
        return self._clean_text(phase.get("description") or phase.get("code"))

    def _format_countries(self, countries: Any) -> str:
        if not isinstance(countries, list):
            return ""

        badges = [
            country.get("country_name") or country.get("country_code")
            for country in countries
            if isinstance(country, dict)
        ]
        cleaned = [self._clean_text(name) for name in badges if name]
        if not cleaned:
            return ""
        return format_html_join(
            "",
            '<span class="tag tag-small">{}</span>',
            ((name,) for name in cleaned),
        )

    def _format_date(self, value: Any) -> str:
        if value in (None, ""):
            return ""
        if isinstance(value, str):
            # ``jsonb`` dates can be stored as ISO formatted strings.
            parsed = self._parse_iso_datetime(value)
            if parsed is None:
                return value
            return date_format(parsed.date(), format="DATE_FORMAT", use_l10n=True)
        if isinstance(value, datetime):
            return date_format(value.date(), format="DATE_FORMAT", use_l10n=True)
        if isinstance(value, date):
            return date_format(value, format="DATE_FORMAT", use_l10n=True)
        if hasattr(value, "date"):
            return date_format(value.date(), format="DATE_FORMAT", use_l10n=True)
        return self._clean_text(value)

    def _parse_iso_datetime(self, value: str) -> Optional[datetime]:
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return None
