from __future__ import annotations

import json
from typing import Any

from django.db import connection
from django.views.generic import TemplateView


class TrialListView(TemplateView):
    template_name = "admin/trials_list.html"

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
            trials = [item for item in payload if isinstance(item, dict)]
        elif isinstance(payload, dict):
            trials = [payload]

        headers: list[str] = []
        if trials:
            headers = list(trials[0].keys())

        context.update({
            "trials": trials,
            "headers": headers,
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
