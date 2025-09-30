"""backend URL Configuration."""

from django.contrib import admin
from django.urls import path

from trials.views import TrialCreateView, TrialListView


urlpatterns = [
    path("", TrialListView.as_view(), name="trial-list"),
    path("trials/create/", TrialCreateView.as_view(), name="trial-create"),
    path("admin/", admin.site.urls),
]
