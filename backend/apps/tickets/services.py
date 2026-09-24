from apps.tickets.models import Ticket


def build_ticket_payload(ticket):
    """Serialize the full booking into a ticket payload for e-ticket / PDF use."""
    booking = ticket.booking
    passengers = [
        {"full_name": p.full_name, "age": p.age, "gender": p.gender, "id_type": p.id_type, "id_number": p.id_number}
        for p in booking.passengers.all()
    ]
    seats = [{"label": s.label, "coach": s.coach_name, "state": s.state} for s in booking.seats.all()]
    payload = {
        "pnr": ticket.pnr,
        "ticket_number": ticket.ticket_number,
        "status": ticket.status,
        "transport_type": booking.transport_type,
        "vehicle_name": booking.vehicle_name,
        "vehicle_number": booking.vehicle_number,
        "vehicle_type": booking.vehicle_type,
        "travel_date": booking.travel_date.isoformat(),
        "departure_time": booking.departure_time.isoformat() if booking.departure_time else None,
        "arrival_time": booking.arrival_time.isoformat() if booking.arrival_time else None,
        "source": booking.source,
        "destination": booking.destination,
        "source_code": booking.source_code,
        "destination_code": booking.destination_code,
        "boarding_point": booking.boarding_point,
        "dropping_point": booking.dropping_point,
        "passengers": passengers,
        "seats": seats,
        "fare": {
            "passenger_fare": str(booking.passenger_fare),
            "service_fee": str(booking.service_fee),
            "tax": str(booking.tax),
            "discount": str(booking.discount),
            "total_amount": str(booking.total_amount),
        },
        "payment": {
            "status": booking.payments.order_by("-created_at").first().status if booking.payments.exists() else "PENDING",
            "reference": booking.payments.order_by("-created_at").first().reference if booking.payments.exists() else "",
        },
        "qr_data": ticket.qr_data,
        "issued_at": ticket.issued_at.isoformat(),
        "booking_id": booking.id,
    }
    ticket.payload = payload
    ticket.save(update_fields=["payload"])
    return payload