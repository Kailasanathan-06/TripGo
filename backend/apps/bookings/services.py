import logging
import random
import string

from decimal import Decimal
from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.common.exceptions import SeatUnavailableError

logger = logging.getLogger("tripgo")


def _money(value, default=Decimal("0")):
    try:
        return Decimal(str(value))
    except Exception:
        return default


def generate_pnr():
    """Unique, user-friendly booking reference e.g. TG84K92P1."""
    while True:
        suffix = "".join(random.choices(string.ascii_uppercase + string.digits, k=8))
        pnr = f"TG{suffix}"
        from apps.tickets.models import Ticket

        if not Ticket.objects.filter(pnr=pnr).exists():
            return pnr.upper()


def generate_ticket_number(booking_id):
    return f"TK{int(timezone.now().timestamp())}{booking_id}"


def compute_fare(vehicle_fare, passenger_count, service_fee, discount=Decimal("0"), tax_rate=Decimal("0.05")):
    """Server-side fare engine. The client never calculates totals."""
    passenger_fare = _money(vehicle_fare) * int(passenger_count)
    service = _money(service_fee)
    tax = (passenger_fare * tax_rate).quantize(Decimal("1.00"))
    discount_val = min(_money(discount), passenger_fare)
    total = passenger_fare + service + tax - discount_val
    return {
        "passenger_fare": passenger_fare,
        "service_fee": service,
        "tax": tax,
        "discount": discount_val,
        "total_amount": total,
    }


def _release_bus_seats(seats):
    for seat in seats:
        seat.state = "AVAILABLE"
        seat.booked_by = None
        seat.hold_expires_at = None
        seat.locked_booking_id = None
    if seats:
        type(seats[0]).objects.bulk_update(seats, ["state", "booked_by", "hold_expires_at", "locked_booking_id"])


def _release_train_berths(berths):
    for b in berths:
        b.state = "AVAILABLE"
        b.booked_by = None
        b.hold_expires_at = None
        b.locked_booking_id = None
    if berths:
        type(berths[0]).objects.bulk_update(berths, ["state", "booked_by", "hold_expires_at", "locked_booking_id"])


def _mark_seats_booked(seats):
    for seat in seats:
        seat.state = "BOOKED"
        seat.hold_expires_at = None
    if seats:
        type(seats[0]).objects.bulk_update(seats, ["state", "hold_expires_at"])


def release_expired_holds():
    """Performs cleanup of seats whose hold window has lapsed."""
    now = timezone.now()
    from apps.buses.models import BusSeat
    from apps.trains.models import TrainBerth

    expired_seats = list(BusSeat.objects.filter(state="HELD", hold_expires_at__lte=now))
    from apps.bookings.models import Booking

    for s in expired_seats:
        Booking.objects.filter(id=s.locked_booking_id, state="HELD").update(state="EXPIRED")
    _release_bus_seats(expired_seats)

    expired_berths = list(TrainBerth.objects.filter(state="HELD", hold_expires_at__lte=now))
    for b in expired_berths:
        Booking.objects.filter(id=b.locked_booking_id, state="HELD").update(state="EXPIRED")
    _release_train_berths(expired_berths)


@transaction.atomic
def hold_seats(booking, seat_labels, coach_name=""):
    """Hold seats for a booking with row-level locking to prevent double booking."""
    release_expired_holds()
    now = timezone.now()
    hold_until = now + timezone.timedelta(minutes=settings.SEAT_HOLD_MINUTES)

    chosen_bus = booking.bus_schedule
    chosen_train = booking.train_schedule
    coach = booking.train_coach

    if booking.transport_type == "bus":
        seats = list(
            chosen_bus.seats.select_for_update()
            .filter(seat_number__in=seat_labels)
            .order_by("seat_number")
        )
        if len(seats) != len(set(seat_labels)):
            raise SeatUnavailableError("One or more selected seats were not found.")
        for seat in seats:
            if seat.state == "BOOKED":
                raise SeatUnavailableError(f"Seat {seat.seat_number} is already booked.")
            if seat.state == "HELD":
                if seat.hold_expires_at and seat.hold_expires_at > now and seat.locked_booking_id and seat.locked_booking_id != booking.id:
                    raise SeatUnavailableError(f"Seat {seat.seat_number} is being held by another user.")
                seat.state = "AVAILABLE"
            seat.state = "HELD"
            seat.booked_by = booking.user
            seat.hold_expires_at = hold_until
            seat.locked_booking_id = booking.id
        BusSeatBulk = seats[0].__class__
        BusSeatBulk.objects.bulk_update(seats, ["state", "booked_by", "hold_expires_at", "locked_booking_id"])
        enrolled = seats
    else:
        if coach is None:
            raise SeatUnavailableError("A coach is required for train bookings.")
        berths = list(
            coach.berths.select_for_update()
            .filter(berth_number__in=seat_labels)
            .order_by("berth_number")
        )
        if len(berths) != len(set(seat_labels)):
            raise SeatUnavailableError("One or more selected berths were not found.")
        for b in berths:
            if b.state == "BOOKED":
                raise SeatUnavailableError(f"Berth {b.berth_number} is already booked.")
            if b.state == "HELD":
                if b.hold_expires_at and b.hold_expires_at > now and b.locked_booking_id and b.locked_booking_id != booking.id:
                    raise SeatUnavailableError(f"Berth {b.berth_number} is being held by another user.")
                b.state = "AVAILABLE"
            b.state = "HELD"
            b.booked_by = booking.user
            b.hold_expires_at = hold_until
            b.locked_booking_id = booking.id
        BerthBulk = berths[0].__class__
        BerthBulk.objects.bulk_update(berths, ["state", "booked_by", "hold_expires_at", "locked_booking_id"])
        enrolled = berths

    booking.state = "HELD"
    booking.hold_expires_at = hold_until
    booking.save(update_fields=["state", "hold_expires_at", "updated_at"])

    from apps.bookings.models import BookingSeat

    for seat in enrolled:
        label = seat.seat_number if booking.transport_type == "bus" else seat.berth_number
        BookingSeat.objects.create(
            booking=booking,
            label=label,
            bus_seat=seat if booking.transport_type == "bus" else None,
            train_berth=seat if booking.transport_type == "train" else None,
            coach_name=coach_name,
            state="HELD",
        )
    return booking


@transaction.atomic
def confirm_booking(booking):
    """After successful payment: mark seats BOOKED, generate PNR + ticket."""
    from apps.tickets.models import Ticket
    from apps.tickets.services import build_ticket_payload

    seats = booking.seats.all()
    if booking.transport_type == "bus":
        _mark_seats_booked([s.bus_seat for s in seats if s.bus_seat])
    else:
        _mark_seats_booked([s.train_berth for s in seats if s.train_berth])
        coach = booking.train_coach
        if coach:
            coach.available = max(0, coach.available - booking.seats.count())
            coach.save(update_fields=["available"])

    booking.state = "CONFIRMED"
    booking.hold_expires_at = None
    booking.save(update_fields=["state", "hold_expires_at", "updated_at"])

    pnr = generate_pnr()
    ticket = Ticket.objects.create(
        booking=booking,
        pnr=pnr,
        ticket_number=generate_ticket_number(booking.id),
        status="GENERATED",
        qr_data=f"TRIPGO:TICKET:{pnr}",
        pdf_url="",
    )
    build_ticket_payload(ticket)
    return ticket


@transaction.atomic
def cancel_booking(booking, reason="Cancelled by user"):
    """Release seats and cancel the booking. Confirmed bookings keep PNR history."""
    seats = booking.seats.all()
    if booking.transport_type == "bus":
        _release_bus_seats([s.bus_seat for s in seats if s.bus_seat])
    else:
        _release_train_berths([s.train_berth for s in seats if s.train_berth])
        coach = booking.train_coach
        if coach:
            coach.available = coach.total_berths - coach.berths.filter(state="BOOKED").count()
            coach.save(update_fields=["available"])

    booking.state = "CANCELLED"
    booking.hold_expires_at = None
    booking.save(update_fields=["state", "hold_expires_at", "updated_at"])

    from apps.tickets.models import Ticket

    Ticket.objects.filter(booking=booking, status="GENERATED").update(status="CANCELLED")
    return booking