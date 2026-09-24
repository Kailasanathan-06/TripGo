# TRIPGO

**Your Journey. One Smart Ticket.**

A full-stack bus & railway ticket reservation system:

- **Backend** — Django 5 + Django REST Framework + PostgreSQL (SQLite fallback), JWT auth, real seat-locking booking engine, mock payment gateway state machine, PNR + e-ticket generation (incl. PDF), offers, notifications.
- **Flutter app** — Riverpod + go_router, bus/train search, interactive seat & berth maps, passenger forms, coupon checkout, mock UPI/web/QR payment screens, e-ticket with scannable QR + PDF download, bookings, offers, inbox, profile, theme settings.

---

## Repository layout

```
.
├── backend/               # Django REST API
│   └── apps/
│       ├── accounts/      # register/login/JWT, forgot password + OTP, profile
│       ├── cities/        # City / Station
│       ├── buses/         # Bus, schedules, seat map, amenities, boarding points
│       ├── trains/        # Train, route stations, coaches, berth map
│       ├── bookings/      # booking, hold/confirm/cancel, fare engine, PNR
│       ├── payments/      # mock payment gateway (start/success/failure/cancel)
│       ├── tickets/       # e-ticket + QR + PDF payload, PNR lookup
│       ├── offers/        # coupons + validation
│       └── notifications/ # booking/payment push-alikes
├── frontend/              # Flutter app
│   └── lib/
│       ├── core/          # theme, routing, api client, storage, errors, utils
│       ├── shared/        # models, services, riverpod providers, widgets
│       └── features/      # screens (auth, home, search, bus, train, payment, tickets…)
└── docs/                  # (optional) diagrams / notes
```

---

## Backend — quick start

```bash
cd backend
python -m venv .venv                 # Python 3.12/3.13 recommended
.venv\Scripts\activate               # Windows  (macOS/Linux: source .venv/bin/activate)
pip install -r requirements.txt

python manage.py migrate
python manage.py seed_demo_data      # 12 cities, buses, trains, seats, berths, offers
python manage.py runserver 0.0.0.0:8000
```

Database defaults to **SQLite**. For **PostgreSQL** set `DATABASE_URL` first
(see `.env.example`), e.g. `postgres://user:pass@localhost:5432/tripgo`.

### Demo accounts (created by `seed_demo_data`)

| Role    | Email              | Password    |
| ------- | ------------------ | ----------- |
| User    | `demo@tripgo.app`  | `demo12345` |
| Admin   | `admin@tripgo.app` | `admin12345` |

### Run tests

```bash
cd backend
python manage.py test        # 10 tests: auth, search, payment success/failure, 2-user race, cancellation
```

### Key API endpoints

```
POST /api/auth/register/ | login/ | refresh/ | logout/ | me/ | forgot-password/ | verify-otp/
GET  /api/cities/?q=…     GET/POST /api/buses/               GET /api/buses/{id}/seats/
GET  /api/trains/?…       GET /api/trains/{id}/coaches/      GET /api/trains/coaches/{idx}/berths/
POST /api/bookings/       GET /api/bookings/list/            POST /api/bookings/{id}/cancel/ | hold/
POST /api/payments/mock/  # {booking_id, method, action: start|success|failure|cancel}
GET  /api/payments/{id}/  POST /api/payments/{id}/retry/ | cancel/
GET  /api/tickets/{id}/   GET /api/tickets/{id}/pdf/         GET /api/pnr/{pnr}/
GET  /api/offers/         POST /api/offers/validate/
GET  /api/notifications/  POST /api/notifications/{id}/read/ | read-all/
```

---

## Flutter — quick start

```bash
cd frontend
flutter pub get
flutter run                  # uses http://10.0.2.2:8000/api/ by default
```

- The API base URL is compile-time configurable:
  `flutter run --dart-define=API_BASE_URL=http://<your-ip>:8000/api/`
- Use key `demo@tripgo.app` / `demo12345` from the login screen ("Use demo account").

### Tests

```bash
cd frontend
flutter test
```

---

## How the booking flow works

1. User searches bus/train → picks seats/berths.
2. `POST /api/bookings/` creates a `HELD` booking and **locks the seats**
   (`select_for_update`) for `SEAT_HOLD_MINUTES`; concurrent requests for the same
   seat get `409`.
3. User pays via the mock gateway. `action=success` → booking `CONFIRMED`,
   PNR (`TG` + random) and e-ticket generated, QR payload built, notification sent.
   `failure`/`cancel` → seats released, no ticket.
4. Expired holds are cleaned up automatically by `release_expired_holds`.

---

## What's tested (Django)

- Auth register/login/`/me/`.
- Bus search + train search shape.
- Payment `SUCCESS` → booking CONFIRMED, PNR + ticket created, seat `BOOKED`.
- Payment `FAILED` / `CANCELLED` → seats released, no PNR/ticket.
- Two users racing for the same seat → second gets `409`.
- Train berth booking + cancellation releases the berth.