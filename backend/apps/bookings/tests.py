from django.test import TestCase, TransactionTestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.buses.models import Bus, BusSchedule, BusSeat
from apps.cities.models import City, Station
from apps.trains.models import Train, TrainBerth, TrainCoach, TrainSchedule, TrainStation


def make_bus_schedule():
    chennai = City.objects.create(name="TestChennai", state="TN")
    bangalore = City.objects.create(name="TestBangalore", state="KA")
    bus = Bus.objects.create(name="Test Bus", operator="TestOps", bus_type="AC_SLEEPER", total_seats=2)
    schedule = BusSchedule.objects.create(
        bus=bus,
        source_city=chennai,
        destination_city=bangalore,
        boarding_point="X",
        boarding_time="20:00:00",
        dropping_point="Y",
        dropping_time="06:00:00",
        duration_minutes=600,
        base_fare=500,
    )
    BusSeat.objects.create(schedule=schedule, seat_number="1", row=1, floor=1, state="AVAILABLE")
    BusSeat.objects.create(schedule=schedule, seat_number="2", row=1, floor=1, state="AVAILABLE")
    return schedule


def make_train_schedule():
    chennai = City.objects.create(name="TrainChennai", state="TN")
    bangalore = City.objects.create(name="TrainBangalore", state="KA")
    train = Train.objects.create(number="10001", name="Test Express", train_type="Express", runs_on="1234567")
    src = Station.objects.create(name="T CHN", code="TCH", city=chennai, kind="train")
    dst = Station.objects.create(name="T BLR", code="TBL", city=bangalore, kind="train")
    TrainStation.objects.create(train=train, station=src, order=1, departure_time="08:00:00")
    TrainStation.objects.create(train=train, station=dst, order=2, arrival_time="16:00:00", distance_km=400)
    schedule = TrainSchedule.objects.create(
        train=train,
        source_station=src,
        destination_station=dst,
        travel_date=timezone.localdate() + timezone.timedelta(days=1),
        duration_minutes=480,
        distance_km=400,
    )
    coach = TrainCoach.objects.create(schedule=schedule, name="B1", coach_class="SL", total_berths=2, class_fare=300)
    TrainBerth.objects.create(coach=coach, berth_number="1L", type="SL", state="AVAILABLE")
    TrainBerth.objects.create(coach=coach, berth_number="2L", type="SL", state="AVAILABLE")
    return schedule, coach


def register(client, email, password="pass12345"):
    return client.post(
        reverse("register"),
        {
            "username": email.split("@")[0],
            "email": email,
            "first_name": "T",
            "last_name": "U",
            "phone": "9000000000",
            "password": password,
            "password2": password,
        },
        format="json",
    )


class AuthTests(TestCase):
    def test_register_login_me(self):
        client = APIClient()
        resp = register(client, "auth@test.com")
        self.assertEqual(resp.status_code, 201)
        self.assertIn("access", resp.json()["data"])
        login = client.post(reverse("login"), {"email": "auth@test.com", "password": "pass12345"}, format="json")
        self.assertEqual(login.status_code, 200)
        client.credentials(HTTP_AUTHORIZATION="Bearer " + login.json()["data"]["access"])
        me = client.get(reverse("me"))
        self.assertEqual(me.status_code, 200)
        self.assertEqual(me.json()["data"]["email"], "auth@test.com")

    def test_login_wrong_password(self):
        client = APIClient()
        register(client, "bad@test.com")
        resp = client.post(reverse("login"), {"email": "bad@test.com", "password": "nope"}, format="json")
        self.assertEqual(resp.status_code, 401)


class SearchTests(TestCase):
    def setUp(self):
        self.schedule = make_bus_schedule()

    def test_bus_search(self):
        client = APIClient()
        resp = client.get(reverse("bus_search"), {"source": "TestChennai", "destination": "TestBangalore"})
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["count"], 1)

    def test_train_search(self):
        schedule, coach = make_train_schedule()
        client = APIClient()
        resp = client.get(reverse("train_search"), {"source": "TrainChennai", "destination": "TrainBangalore"})
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["count"], 1)


class BookingPaymentFlowTests(TransactionTestCase):
    """Core end-to-end flow: hold -> pay -> PNR -> ticket; failures release seats."""

    def setUp(self):
        self.schedule = make_bus_schedule()
        self.client1 = APIClient()
        register(self.client1, "u1@test.com")
        self.client2 = APIClient()
        register(self.client2, "u2@test.com")
        self.token1 = self.client1.post(reverse("login"), {"email": "u1@test.com", "password": "pass12345"}, format="json").json()["data"]["access"]
        self.token2 = self.client2.post(reverse("login"), {"email": "u2@test.com", "password": "pass12345"}, format="json").json()["data"]["access"]
        self.client1.credentials(HTTP_AUTHORIZATION="Bearer " + self.token1)
        self.client2.credentials(HTTP_AUTHORIZATION="Bearer " + self.token2)

    def _create_booking(self, client, seat="1"):
        return client.post(
            reverse("booking_create"),
            {
                "transport_type": "bus",
                "schedule_id": self.schedule.id,
                "seat_labels": [seat],
                "passengers": [{"full_name": "Test Passenger", "age": 30, "gender": "M", "mobile": "9000000000"}],
            },
            format="json",
        )

    def test_payment_success_creates_pnr_and_ticket(self):
        resp = self._create_booking(self.client1)
        self.assertEqual(resp.status_code, 201, resp.content)
        booking_id = resp.json()["data"]["id"]
        pay = self.client1.post(reverse("payment_mock"), {"booking_id": booking_id, "method": "app", "action": "success"}, format="json")
        self.assertEqual(pay.status_code, 200)
        data = pay.json()["data"]["payment"]
        self.assertEqual(data["status"], "SUCCESS")
        booking = pay.json()["data"]["booking"]
        self.assertEqual(booking["state"], "CONFIRMED")
        self.assertTrue(booking["pnr"], "PNR must exist after successful payment")
        seat = BusSeat.objects.get(schedule=self.schedule, seat_number="1")
        self.assertEqual(seat.state, "BOOKED")
        lookup = self.client1.get(reverse("pnr_lookup", args=[booking["pnr"]]))
        self.assertEqual(lookup.status_code, 200)

    def test_payment_failure_releases_seat_no_pnr(self):
        resp = self._create_booking(self.client1)
        booking_id = resp.json()["data"]["id"]
        pay = self.client1.post(reverse("payment_mock"), {"booking_id": booking_id, "action": "failure"}, format="json")
        self.assertEqual(pay.json()["data"]["payment"]["status"], "FAILED")
        booking = self.client1.get(reverse("booking_detail", args=[booking_id])).json()["data"]
        self.assertIsNone(booking["pnr"])
        self.assertNotEqual(booking["state"], "CONFIRMED")
        seat = BusSeat.objects.get(schedule=self.schedule, seat_number="1")
        self.assertEqual(seat.state, "AVAILABLE")

    def test_payment_cancel_releases_seat_no_ticket(self):
        resp = self._create_booking(self.client1)
        booking_id = resp.json()["data"]["id"]
        self.client1.post(reverse("payment_mock"), {"booking_id": booking_id, "action": "cancel"}, format="json")
        seat = BusSeat.objects.get(schedule=self.schedule, seat_number="1")
        self.assertEqual(seat.state, "AVAILABLE")

    def test_two_users_cannot_book_same_seat(self):
        r1 = self._create_booking(self.client1, "2")
        self.assertEqual(r1.status_code, 201)
        r2 = self._create_booking(self.client2, "2")
        self.assertEqual(r2.status_code, 409, "Second user holding the same held seat must be rejected")

    def test_cancel_booking_releases_seat(self):
        r = self._create_booking(self.client1, "2")
        booking_id = r.json()["data"]["id"]
        self.client1.post(reverse("booking_cancel", args=[booking_id]), format="json")
        seat = BusSeat.objects.get(schedule=self.schedule, seat_number="2")
        self.assertEqual(seat.state, "AVAILABLE")


class TrainBookingTests(TransactionTestCase):
    def setUp(self):
        self.schedule, self.coach = make_train_schedule()
        self.client = APIClient()
        register(self.client, "train@test.com")
        login = self.client.post(reverse("login"), {"email": "train@test.com", "password": "pass12345"}, format="json").json()
        self.client.credentials(HTTP_AUTHORIZATION="Bearer " + login["data"]["access"])

    def test_train_booking_success(self):
        resp = self.client.post(
            reverse("booking_create"),
            {
                "transport_type": "train",
                "schedule_id": self.schedule.id,
                "coach_id": self.coach.id,
                "seat_labels": ["1L", "2L"],
                "passengers": [
                    {"full_name": "A", "age": 25, "gender": "M"},
                    {"full_name": "B", "age": 27, "gender": "F"},
                ],
            },
            format="json",
        )
        self.assertEqual(resp.status_code, 201, resp.content)
        booking_id = resp.json()["data"]["id"]
        pay = self.client.post(reverse("payment_mock"), {"booking_id": booking_id, "action": "success"}, format="json")
        self.assertEqual(pay.status_code, 200)
        from apps.tickets.models import Ticket

        self.assertTrue(Ticket.objects.filter(booking_id=booking_id).exists())
        self.coach.refresh_from_db()
        self.assertEqual(self.coach.available, 0)