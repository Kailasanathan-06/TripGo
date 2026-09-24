from django.urls import path

from .views import PNRLookupView, TicketDetailView, TicketPdfView

urlpatterns = [
    path("tickets/<int:pk>/", TicketDetailView.as_view(), name="ticket_detail"),
    path("tickets/<int:pk>/pdf/", TicketPdfView.as_view(), name="ticket_pdf"),
    path("pnr/<str:pnr>/", PNRLookupView.as_view(), name="pnr_lookup"),
]