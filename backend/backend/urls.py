"""backend URL Configuration."""

from django.contrib import admin
from django.urls import path

from trials.views import TrialListView


urlpatterns = [
    path("", TrialListView.as_view(), name="trial-list"),
    path("admin/", admin.site.urls),
]
