import random
from datetime import date, time, timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.accounts.models import SavedPassenger, User
from apps.buses.models import Bus, BusSchedule, BusSeat
from apps.cities.models import City, Station
from apps.notifications.models import Notification
from apps.offers.models import Offer
from apps.trains.models import Train, TrainBerth, TrainCoach, TrainSchedule, TrainStation

CITIES = [
    ("Chennai", "Tamil Nadu"),
    ("Bengaluru", "Karnataka"),
    ("Hyderabad", "Telangana"),
    ("Mumbai", "Maharashtra"),
    ("Delhi", "Delhi NCR"),
    ("Pune", "Maharashtra"),
    ("Coimbatore", "Tamil Nadu"),
    ("Madurai", "Tamil Nadu"),
    ("Kochi", "Kerala"),
    ("Tiruchirappalli", "Tamil Nadu"),
]

STATIONS = {
    "Chennai": [("Chennai Central", "MAS"), ("Chennai Egmore", "MS"), ("Koyambedu Bus Stand", "KYD")],
    "Bengaluru": [("KSR Bengaluru City", "SBC"), ("KR Puram", "KJM"), ("SATP Bus stand Attibele", "ATP")],
    "Hyderabad": [("Secunderabad Junction", "SC"), ("Hyderabad Deccan", "HYB"), ("MGBS Hyderabad", "MGB")],
    "Mumbai": [("Mumbai CSMT", "CSMT"), ("Mumbai Central", "MMCT"), ("Borivali", "BVI")],
    "Delhi": [("New Delhi", "NDLS"), ("Old Delhi Junction", "DLI"), ("ISBT Kashmere Gate", "KBY")],
    "Pune": [("Pune Junction", "PUNE"), ("Shivajinagar", "SVJR"), ("Pune Station bus bay", "PUN")],
    "Coimbatore": [("Coimbatore Junction", "CBE"), ("Coimbatore North", "CBF"), ("Gandhipuram", "GPD")],
    "Madurai": [("Madurai Junction", "MDU"), ("Madurai Mattuthavani", "MDN")],
    "Kochi": [("Ernakulam Junction", "ERS"), ("Ernakulam Town", "ERN"), ("Vyttila Hub", "VYT")],
    "Tiruchirappalli": [("Tiruchirappalli Junction", "TPJ"), ("Central Bus Stand Trichy", "CST")],
}

BUS_OPERATORS = [
    ("VRL Travels", "AC_SLEEPER", True, True, ["Water Bottle", "Charging Point", "Blanket", "Reading Light", "CCTV"]),
    ("SRS Travels", "AC_SLEEPER", True, True, ["Water Bottle", "Charging Point", "Blanket", "TV"]),
    ("Orange Travels", "AC_SEATER", True, False, ["Water Bottle", "Charging Point", "WiFi"]),
    ("KPN Travels", "NON_AC_SLEEPER", False, True, ["Water Bottle", "Reading Light"]),
    ("IntrCity SmartBus", "AC_DLX", True, True, ["Water Bottle", "WiFi", "Snacks", "Charging Point", "CCTV", "Reading Light"]),
    ("TNFCT Red Bus", "NON_AC_SEATER", False, False, ["CCTV", "Emergency Exit"]),
    ("Parveen Travels", "AC_SLEEPER", True, True, ["Water Bottle", "Blanket", "Charging Point"]),
]

CITY_PAIRS = [
    ("Chennai", "Bengaluru"),
    ("Bengaluru", "Hyderabad"),
    ("Chennai", "Coimbatore"),
    ("Chennai", "Madurai"),
    ("Bengaluru", "Pune"),
    ("Hyderabad", "Mumbai"),
    ("Mumbai", "Pune"),
    ("Coimbatore", "Kochi"),
    ("Madurai", "Tiruchirappalli"),
    ("Chennai", "Tiruchirappalli"),
]

BUS_FARE = {
    "AC_SLEEPER": 950,
    "NON_AC_SLEEPER": 700,
    "AC_SEATER": 650,
    "NON_AC_SEATER": 480,
    "AC_DLX": 1200,
}

TRAINS = [
    ("12657", "Kanniyakumari Express", "Superfast", "1234567"),
    ("12635", "Vaigai Express", "Superfast", "1234567"),
    ("12691", "Chennai - Coimbatore Express", "Superfast", "1234567"),
    ("12201", "Mumbai LTT Garib Rath", "Garib Rath", "1234567"),
    ("12951", "Mumbai Rajdhani", "Rajdhani", "1234567"),
    ("12841", "Coromandel Express", "Superfast", "1234567"),
    ("12027", "Chennai - Mysuru Shatabdi", "Shatabdi", "23456"),
    ("22625", "Coimbatore - Kochi Intercity", "Intercity", "1234567"),
    ("12633", "Kanyakumari - Chennai Express", "Superfast", "1234567"),
    ("22673", "Madurai - Tiruchchirappalli Passenger", "Passenger", "1234567"),
]

CLASS_BERTHS = {
    "SL": (108, "S", 480),
    "3A": (72, "B", 720),
    "2A": (64, "A", 880),
    "1A": (24, "H", 1600),
    "CC": (78, "C", 540),
    "2S": (100, "D", 180),
}


class Command(BaseCommand):
    help = "Seed TripGo with realistic demo data (cities, stations, buses, trains, offers, users)."

    def handle(self, *args, **options):
        self.clean_slate()

        city_map = {}
        for name, state in CITIES:
            city_map[name] = City.objects.create(name=name, state=state, is_popular=name in ("Chennai", "Bengaluru", "Hyderabad", "Mumbai", "Delhi"))

        for city_name, stations in STATIONS.items():
            city = city_map[city_name]
            for sidx, (sname, code) in enumerate(stations):
                Station.objects.create(name=sname, code=code, city=city, kind="both" if city_name in ("Chennai", "Bengaluru", "Hyderabad", "Mumbai", "Delhi") and sidx < 2 else ("bus" if "Bus" in sname or "ISBT" in sname or "Hub" in sname else "train"))

        self.seed_buses(city_map)
        self.seed_trains()
        self.seed_offers()
        self.seed_users(city_map)

        self.stdout.write(self.style.SUCCESS("TripGo demo data seeded successfully."))

    def clean_slate(self):
        from django.db import transaction

        with transaction.atomic():
            for m in (BusSeat, BusSchedule, Bus, Station, City, TrainStation, TrainBerth, TrainCoach, TrainSchedule, Train, Offer, Notification, SavedPassenger):
                m.objects.all().delete()
            from apps.tickets.models import Ticket
            from apps.bookings.models import Booking, BookingPassenger, BookingSeat
            from apps.payments.models import Payment

            BookingPassenger.objects.all().delete()
            BookingSeat.objects.all().delete()
            Booking.objects.all().delete()
            Tag = Ticket
            Tag.objects.all().delete()
            Payment.objects.all().delete()
            User.objects.exclude(username="admin").delete()

    def seed_buses(self, city_map):
        rng = random.Random(7)
        for pair in CITY_PAIRS:
            src_name, dst_name = pair
            src, dst = city_map[src_name], city_map[dst_name]
            for _ in range(2):
                op_name, bus_type, is_ac, is_sleeper, amenities = rng.choice(BUS_OPERATORS)
                bus = Bus.objects.create(
                    name=f"{op_name} {src_name}-{dst_name}",
                    operator=op_name,
                    bus_type=bus_type,
                    total_seats=40,
                    rating=round(rng.uniform(3.6, 4.8), 1),
                    amenities=amenities,
                    is_ac=is_ac,
                    is_sleeper=is_sleeper,
                )
                dep_min = rng.choice([190, 350, 390, 640, 700, 1080])
                dep_seconds = dep_min * 60
                duration = rng.choice([360, 420, 480, 540, 600])
                dep_time = time.fromisoformat(f"{dep_seconds // 3600:02d}:{((dep_seconds % 3600) // 60):02d}:00")
                arr_seconds = (dep_seconds + duration * 60) % 86400
                arr_time = time.fromisoformat(f"{arr_seconds // 3600:02d}:{((arr_seconds % 3600) // 60):02d}:00")
                fare = BUS_FARE[bus_type] + rng.randint(-40, 120)
                BusSchedule.objects.create(
                    bus=bus,
                    source_city=src,
                    destination_city=dst,
                    boarding_point=f"{op_name} Booking Office, {src_name}",
                    boarding_time=dep_time,
                    dropping_point=f"{dst_name} Central Bus Terminus",
                    dropping_time=arr_time,
                    duration_minutes=duration,
                    base_fare=fare,
                    discount_amount=rng.choice([0, 0, 50, 100]),
                    rating=round(rng.uniform(3.7, 4.8), 1),
                    reviews_count=rng.randint(120, 2400),
                )
        for schedule in BusSchedule.objects.all():
            self.create_bus_seats(schedule)

    def create_bus_seats(self, schedule, deck1_rows=10, deck2_rows=10):
        seats, seat_no = [], 1
        for floor, rows in ((1, deck1_rows), (2, deck2_rows)):
            for row in range(1, rows + 1):
                for _ in range(2):
                    state = "AVAILABLE" if random.random() > 0.18 else "BOOKED"
                    seats.append(BusSeat(schedule=schedule, seat_number=str(seat_no), row=row, floor=floor, state=state))
                    seat_no += 1
        BusSeat.objects.bulk_create(seats)

    def seed_trains(self):
        rng = random.Random(11)
        i = 0
        for num, name, ttype, days in TRAINS:
            pair = CITY_PAIRS[i % len(CITY_PAIRS)]
            src, dst = pair
            src_stn = Station.objects.filter(city__name=src, kind__in=["train", "both"]).first()
            dst_stn = Station.objects.filter(city__name=dst, kind__in=["train", "both"]).first()
            if not src_stn or not dst_stn:
                i += 1
                continue
            train = Train.objects.create(number=num, name=name, train_type=ttype, runs_on=days, rating=round(rng.uniform(3.8, 4.7), 1))
            dep_seconds = rng.choice([360, 540, 720, 1140]) * 60
            duration = rng.choice([330, 390, 450, 510, 600])
            TrainStation.objects.create(train=train, station=src_stn, order=1, departure_time=_to_time(dep_seconds), platform=str(rng.randint(1, 6)))
            TrainStation.objects.create(train=train, station=dst_stn, order=2, arrival_time=_to_time((dep_seconds + duration * 60) % 86400), platform=str(rng.randint(1, 6)), distance_km=rng.randint(300, 700))
            for offset in range(7):
                d = date.today() + timedelta(days=offset)
                if str(d.isoweekday()) not in days:
                    continue
                schedule = TrainSchedule.objects.create(
                    train=train,
                    source_station=src_stn,
                    destination_station=dst_stn,
                    travel_date=d,
                    duration_minutes=duration,
                    distance_km=rng.randint(300, 700),
                    base_fare=0,
                )
                created_coaches = []
                for cls in ("SL", "3A", "2A", "CC"):
                    total, letter, fee = CLASS_BERTHS[cls]
                    coach = TrainCoach.objects.create(schedule=schedule, name=f"{letter}{rng.randint(1, 9)}", coach_class=cls, total_berths=0, class_fare=CLASS_BERTHS[cls][2], available=0)
                    created_coaches.append(coach)
                    self.create_berths(coach, total, rng)
            i += 1

    def create_berths(self, coach, count, rng):
        berths, booked = [], 0
        for n in range(1, count + 1):
            state = "AVAILABLE" if rng.random() > 0.35 else ("BOOKED" if booked < int(count * 0.2) else "AVAILABLE")
            if state == "BOOKED":
                booked += 1
            berths.append(TrainBerth(coach=coach, berth_number=f"{n}{_berth_suffix(n)}", type=coach.coach_class, state=state))
            coach.total_berths += 1
            if state == "AVAILABLE":
                coach.available += 1
        TrainBerth.objects.bulk_create(berths)
        coach.save(update_fields=["total_berths", "available"])

    def seed_offers(self):
        Offer.objects.create(code="TRIPGO50", title="Flat ₹50 off", description="Flat ₹50 off on your next bus booking above ₹400. Valid on all routes.", discount_amount=50, min_fare=400)
        Offer.objects.create(code="WELCOME100", title="Welcome Bonus", description="Get ₹100 off on your first train booking.", discount_amount=100, min_fare=500, transport_types="train")
        Offer.objects.create(code="SUMMER15", title="Summer Sale 15%", description="15% off on AC sleeper buses during summer.", discount_percent=15, transport_types="bus", valid_from=date.today() - timedelta(days=10), valid_to=date.today() + timedelta(days=90))
        Offer.objects.create(code="TRAIN10", title="Train 10% off", description="10% off on Rajdhani and Shatabdi trains.", discount_percent=10, transport_types="train", valid_from=date.today() - timedelta(days=5), valid_to=date.today() + timedelta(days=60))
        Offer.objects.create(code="KOCHI40", title="Kochi special", description="₹40 off on buses to Kochi above ₹600.", discount_amount=40, min_fare=600, transport_types="bus")

    def seed_users(self, city_map):
        demo = User.objects.create_user(
            username="demo", email="demo@tripgo.app", password="demo12345", first_name="Demo", last_name="User", phone="9876543210"
        )
        User.objects.create_superuser("admin", "admin@tripgo.app", "admin12345")
        SavedPassenger.objects.create(user=demo, full_name="Demo User", age=28, gender="M", mobile="9876543210")
        SavedPassenger.objects.create(user=demo, full_name="Ravi Kumar", age=34, gender="M", mobile="9876501234")
        SavedPassenger.objects.create(user=demo, full_name="Anita Sharma", age=30, gender="F", mobile="9812345670")
        Notification.objects.create(user=demo, type="OFFER", title="Welcome to TripGo!", message="Use code TRIPGO50 for your first booking discount.")
        Notification.objects.create(user=demo, type="OFFER", title="Summer Sale is live", message="Save 15% on select AC Sleeper buses this month.")


def _berth_suffix(n):
    rem = n % 8
    return {1: "L", 2: "U", 3: "LB", 4: "MB", 5: "UB", 6: "SU", 7: "L", 8: "U"}.get(rem, "L")


def _to_time(seconds):
    return time.fromisoformat(f"{seconds // 3600:02d}:{((seconds % 3600) // 60):02d}:00")