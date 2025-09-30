from __future__ import annotations

import json
from typing import Any

from django.db import connection
from django.db import transaction
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpRequest, HttpResponse
from django.shortcuts import redirect
from django.urls import reverse_lazy
from django.views.generic import TemplateView
from django.utils.translation import gettext_lazy as _

from .forms import (
    InterventionFormSet,
    TrialConditionFormSet,
    TrialCountryFormSet,
    TrialDocumentFormSet,
    TrialForm,
)


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


class TrialCreateView(LoginRequiredMixin, TemplateView):
    template_name = "admin/trial_form.html"
    success_url = reverse_lazy("trial-list")

    reference_data: dict[str, list[tuple[Any, str]]]

    def dispatch(self, request: HttpRequest, *args: Any, **kwargs: Any) -> HttpResponse:
        self.reference_data = self._load_reference_data()
        return super().dispatch(request, *args, **kwargs)

    def get(self, request: HttpRequest, *args: Any, **kwargs: Any) -> HttpResponse:
        trial_form = self._build_trial_form()
        country_formset = self._build_country_formset()
        intervention_formset = self._build_intervention_formset()
        condition_formset = self._build_condition_formset()
        document_formset = self._build_document_formset()
        context = self._build_context(
            trial_form,
            country_formset,
            intervention_formset,
            condition_formset,
            document_formset,
        )
        return self.render_to_response(context)

    def post(self, request: HttpRequest, *args: Any, **kwargs: Any) -> HttpResponse:
        trial_form = self._build_trial_form(data=request.POST)
        country_formset = self._build_country_formset(data=request.POST)
        intervention_formset = self._build_intervention_formset(data=request.POST)
        condition_formset = self._build_condition_formset(data=request.POST)
        document_formset = self._build_document_formset(data=request.POST)

        trial_valid = trial_form.is_valid()
        country_valid = country_formset.is_valid()
        intervention_valid = intervention_formset.is_valid()
        condition_valid = condition_formset.is_valid()
        document_valid = document_formset.is_valid()

        if trial_valid and country_valid and intervention_valid and condition_valid and document_valid:
            try:
                with transaction.atomic():
                    trial_id = self._create_trial(trial_form.cleaned_data)
                    self._save_countries(trial_id, country_formset.cleaned_data)
                    self._save_interventions(trial_id, intervention_formset.cleaned_data)
                    self._save_conditions(trial_id, condition_formset.cleaned_data)
                    self._save_documents(trial_id, document_formset.cleaned_data)
            except Exception:  # pragma: no cover - defensive; logging could be added later
                context = self._build_context(
                    trial_form,
                    country_formset,
                    intervention_formset,
                    condition_formset,
                    document_formset,
                    save_error=True,
                )
                return self.render_to_response(context)
            return redirect(self.success_url)

        context = self._build_context(
            trial_form,
            country_formset,
            intervention_formset,
            condition_formset,
            document_formset,
        )
        return self.render_to_response(context)

    def _build_context(
        self,
        trial_form: TrialForm,
        country_formset: TrialCountryFormSet,
        intervention_formset: InterventionFormSet,
        condition_formset: TrialConditionFormSet,
        document_formset: TrialDocumentFormSet,
        *,
        save_error: bool = False,
    ) -> dict[str, Any]:
        return {
            "trial_form": trial_form,
            "formsets": [
                {
                    "title": _("Locations"),
                    "add_text": _("Add another location"),
                    "formset": country_formset,
                },
                {
                    "title": _("Interventions"),
                    "add_text": _("Add another intervention"),
                    "formset": intervention_formset,
                },
                {
                    "title": _("Conditions"),
                    "add_text": _("Add another condition"),
                    "formset": condition_formset,
                },
                {
                    "title": _("Documents"),
                    "add_text": _("Add another document"),
                    "formset": document_formset,
                },
            ],
            "save_error": save_error,
        }

    def _build_trial_form(self, data: dict[str, Any] | None = None) -> TrialForm:
        return TrialForm(
            data=data,
            recruitment_status_choices=self.reference_data.get("recruitment_statuses", []),
            study_phase_choices=self.reference_data.get("study_phases", []),
        )

    def _build_country_formset(self, data: dict[str, Any] | None = None) -> TrialCountryFormSet:
        return TrialCountryFormSet(
            data=data,
            prefix="countries",
            form_kwargs={"country_choices": self.reference_data.get("countries", [])},
        )

    def _build_intervention_formset(self, data: dict[str, Any] | None = None) -> InterventionFormSet:
        return InterventionFormSet(
            data=data,
            prefix="interventions",
            form_kwargs={
                "intervention_type_choices": self.reference_data.get("intervention_types", [])
            },
        )

    def _build_condition_formset(self, data: dict[str, Any] | None = None) -> TrialConditionFormSet:
        return TrialConditionFormSet(
            data=data,
            prefix="conditions",
            form_kwargs={
                "condition_category_choices": self.reference_data.get("condition_categories", [])
            },
        )

    def _build_document_formset(self, data: dict[str, Any] | None = None) -> TrialDocumentFormSet:
        return TrialDocumentFormSet(data=data, prefix="documents")

    def _load_reference_data(self) -> dict[str, list[tuple[Any, str]]]:
        reference_data: dict[str, list[tuple[Any, str]]] = {
            "recruitment_statuses": [],
            "study_phases": [],
            "countries": [],
            "intervention_types": [],
            "condition_categories": [],
        }
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT status_code, COALESCE(description, status_code)"
                " FROM recruitment_statuses ORDER BY description, status_code"
            )
            reference_data["recruitment_statuses"] = [(row[0], row[1]) for row in cursor.fetchall()]

            cursor.execute(
                "SELECT phase_code, COALESCE(description, phase_code)"
                " FROM study_phases ORDER BY description, phase_code"
            )
            reference_data["study_phases"] = [(row[0], row[1]) for row in cursor.fetchall()]

            cursor.execute(
                "SELECT country_id, name FROM countries ORDER BY name"
            )
            reference_data["countries"] = [(row[0], row[1]) for row in cursor.fetchall()]

            cursor.execute(
                "SELECT intervention_type_id, COALESCE(description, type_code)"
                " FROM intervention_types ORDER BY description, type_code"
            )
            reference_data["intervention_types"] = [(row[0], row[1]) for row in cursor.fetchall()]

            cursor.execute(
                "SELECT condition_category_id, COALESCE(name, category_code)"
                " FROM condition_categories ORDER BY name, category_code"
            )
            reference_data["condition_categories"] = [(row[0], row[1]) for row in cursor.fetchall()]

        return reference_data

    def _create_trial(self, cleaned_data: dict[str, Any]) -> int:
        with connection.cursor() as cursor:
            cursor.callproc(
                "create_trial",
                [
                    cleaned_data.get("public_identifier"),
                    cleaned_data.get("official_title"),
                    cleaned_data.get("recruitment_status_code"),
                    cleaned_data.get("study_phase_code") or None,
                    cleaned_data.get("brief_summary") or None,
                    cleaned_data.get("lead_sponsor_name") or None,
                    cleaned_data.get("lead_sponsor_type") or None,
                    cleaned_data.get("lead_sponsor_email") or None,
                ],
            )
            cursor.execute(
                "SELECT trial_id FROM trials WHERE public_identifier = %s ORDER BY trial_id DESC LIMIT 1",
                [cleaned_data.get("public_identifier")],
            )
            row = cursor.fetchone()
        if not row:
            raise ValueError("Failed to determine the created trial identifier")
        return int(row[0])

    def _save_countries(self, trial_id: int, cleaned_data: list[dict[str, Any]]) -> None:
        with connection.cursor() as cursor:
            for form_data in cleaned_data:
                if not form_data or form_data.get("DELETE"):
                    continue
                country_id = form_data.get("country_id")
                if not country_id:
                    continue
                city = form_data.get("city") or None
                site_name = form_data.get("site_name") or None
                cursor.execute(
                    "INSERT INTO trial_countries (trial_id, country_id, city, site_name)"
                    " VALUES (%s, %s, %s, %s)",
                    [trial_id, int(country_id), city, site_name],
                )

    def _save_interventions(self, trial_id: int, cleaned_data: list[dict[str, Any]]) -> None:
        with connection.cursor() as cursor:
            for form_data in cleaned_data:
                if not form_data or form_data.get("DELETE"):
                    continue
                intervention_type_id = form_data.get("intervention_type_id")
                name = form_data.get("name")
                if not intervention_type_id or not name:
                    continue
                description = form_data.get("description") or None
                cursor.execute(
                    "INSERT INTO interventions (trial_id, intervention_type_id, name, description)"
                    " VALUES (%s, %s, %s, %s)",
                    [trial_id, int(intervention_type_id), name, description],
                )

    def _save_conditions(self, trial_id: int, cleaned_data: list[dict[str, Any]]) -> None:
        with connection.cursor() as cursor:
            for form_data in cleaned_data:
                if not form_data or form_data.get("DELETE"):
                    continue
                condition_name = form_data.get("condition_name")
                if not condition_name:
                    continue
                condition_category_id = form_data.get("condition_category_id") or None
                cursor.execute(
                    "INSERT INTO trial_conditions (trial_id, condition_category_id, condition_name)"
                    " VALUES (%s, %s, %s)",
                    [
                        trial_id,
                        int(condition_category_id) if condition_category_id else None,
                        condition_name,
                    ],
                )

    def _save_documents(self, trial_id: int, cleaned_data: list[dict[str, Any]]) -> None:
        with connection.cursor() as cursor:
            for form_data in cleaned_data:
                if not form_data or form_data.get("DELETE"):
                    continue
                document_type = form_data.get("document_type")
                document_url = form_data.get("document_url")
                if not document_type or not document_url:
                    continue
                is_confidential = bool(form_data.get("is_confidential"))
                cursor.execute(
                    "INSERT INTO trial_documents (trial_id, document_type, document_url, is_confidential)"
                    " VALUES (%s, %s, %s, %s)",
                    [trial_id, document_type, document_url, is_confidential],
                )
