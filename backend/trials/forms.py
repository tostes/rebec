"""Forms for managing clinical trial data."""

from __future__ import annotations

from typing import Sequence, Tuple, Union

from django import forms
from django.forms import BaseFormSet, formset_factory
from django.utils.translation import gettext_lazy as _


ChoiceList = Sequence[Tuple[Union[str, int], str]]


class TrialForm(forms.Form):
    """Form describing the core trial details."""

    public_identifier = forms.CharField(
        label=_("Public identifier"),
        max_length=255,
        help_text=_("Unique identifier such as the registry number."),
    )
    official_title = forms.CharField(
        label=_("Official title"),
        widget=forms.Textarea(attrs={"rows": 2}),
    )
    brief_summary = forms.CharField(
        label=_("Brief summary"),
        required=False,
        widget=forms.Textarea(attrs={"rows": 4}),
    )
    recruitment_status_code = forms.ChoiceField(
        label=_("Recruitment status"),
        choices=(),
    )
    study_phase_code = forms.ChoiceField(
        label=_("Study phase"),
        required=False,
        choices=(),
    )
    lead_sponsor_name = forms.CharField(
        label=_("Lead sponsor name"),
        required=False,
        max_length=255,
    )
    lead_sponsor_type = forms.CharField(
        label=_("Lead sponsor type"),
        required=False,
        max_length=255,
    )
    lead_sponsor_email = forms.EmailField(
        label=_("Lead sponsor email"),
        required=False,
    )

    def __init__(
        self,
        *args: object,
        recruitment_status_choices: ChoiceList | None = None,
        study_phase_choices: ChoiceList | None = None,
        **kwargs: object,
    ) -> None:
        super().__init__(*args, **kwargs)
        recruitment_choices = [(str(value), label) for value, label in (recruitment_status_choices or [])]
        study_phase_rendered = [(str(value), label) for value, label in (study_phase_choices or [])]
        self.fields["recruitment_status_code"].choices = [
            ("", _("Select a recruitment status")),
            *recruitment_choices,
        ]
        self.fields["study_phase_code"].choices = [
            ("", _("No study phase specified")),
            *study_phase_rendered,
        ]


class TrialCountryForm(forms.Form):
    country_id = forms.ChoiceField(label=_("Country"), choices=())
    city = forms.CharField(label=_("City"), required=False, max_length=255)
    site_name = forms.CharField(label=_("Site name"), required=False, max_length=255)

    def __init__(
        self,
        *args: object,
        country_choices: ChoiceList | None = None,
        **kwargs: object,
    ) -> None:
        super().__init__(*args, **kwargs)
        self.fields["country_id"].choices = self._with_placeholder(country_choices or [])

    @staticmethod
    def _with_placeholder(choices: ChoiceList) -> list[tuple[str, str]]:
        return [("", _("Select a country"))] + [(str(value), label) for value, label in choices]


class InterventionForm(forms.Form):
    name = forms.CharField(label=_("Name"), max_length=255)
    intervention_type_id = forms.ChoiceField(label=_("Type"), choices=())
    description = forms.CharField(
        label=_("Description"),
        required=False,
        widget=forms.Textarea(attrs={"rows": 2}),
    )

    def __init__(
        self,
        *args: object,
        intervention_type_choices: ChoiceList | None = None,
        **kwargs: object,
    ) -> None:
        super().__init__(*args, **kwargs)
        self.fields["intervention_type_id"].choices = self._with_placeholder(
            intervention_type_choices or [],
            placeholder=_("Select an intervention type"),
        )

    @staticmethod
    def _with_placeholder(choices: ChoiceList, *, placeholder: str) -> list[tuple[str, str]]:
        return [("", placeholder)] + [(str(value), label) for value, label in choices]


class TrialConditionForm(forms.Form):
    condition_name = forms.CharField(label=_("Condition name"), max_length=255)
    condition_category_id = forms.ChoiceField(
        label=_("Condition category"),
        required=False,
        choices=(),
    )

    def __init__(
        self,
        *args: object,
        condition_category_choices: ChoiceList | None = None,
        **kwargs: object,
    ) -> None:
        super().__init__(*args, **kwargs)
        self.fields["condition_category_id"].choices = self._with_placeholder(
            condition_category_choices or [],
            placeholder=_("Select a category"),
        )

    @staticmethod
    def _with_placeholder(choices: ChoiceList, *, placeholder: str) -> list[tuple[str, str]]:
        return [("", placeholder)] + [(str(value), label) for value, label in choices]


class TrialDocumentForm(forms.Form):
    document_type = forms.CharField(label=_("Document type"), max_length=255)
    document_url = forms.URLField(label=_("Document URL"))
    is_confidential = forms.BooleanField(label=_("Confidential"), required=False)


class BaseOptionalFormSet(BaseFormSet):
    """Base formset that ignores forms with no changed data."""

    def clean(self) -> None:  # pragma: no cover - default implementation is sufficient
        super().clean()


TrialCountryFormSet = formset_factory(
    TrialCountryForm,
    extra=1,
    can_delete=True,
    formset=BaseOptionalFormSet,
)

InterventionFormSet = formset_factory(
    InterventionForm,
    extra=1,
    can_delete=True,
    formset=BaseOptionalFormSet,
)

TrialConditionFormSet = formset_factory(
    TrialConditionForm,
    extra=1,
    can_delete=True,
    formset=BaseOptionalFormSet,
)

TrialDocumentFormSet = formset_factory(
    TrialDocumentForm,
    extra=1,
    can_delete=True,
    formset=BaseOptionalFormSet,
)

