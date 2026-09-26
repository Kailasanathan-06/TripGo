# TRIPGO

**Your Journey. One Smart Ticket.**

A full-stack bus & railway ticket reservation system:

- **Backend** — Django 5 + Django REST Framework + PostgreSQL (SQLite fallback), JWT auth, real seat-locking booking engine, mock payment gateway state machine, PNR + e-ticket generation (incl. PDF), offers, notifications.
- **Flutter app** — Riverpod + go_router, bus/train search, interactive seat & berth maps, passenger forms, coupon checkout, mock UPI/web/QR payment screens, e-ticket with scannable QR + PDF download, bookings, offers, inbox, profile, theme settings.
- **Self-contained APK** — the same Django backend is bundled into the Android app with Chaquopy, so it starts by itself when the app opens and stops when the app closes. See [Android app](#android-app--the-server-is-inside-the-apk).

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
python manage.py runserver 127.0.0.1:8000
```

> Bind to `127.0.0.1`, not `0.0.0.0`. `0.0.0.0` is a *listen* address and is not a
> valid destination, so opening `http://0.0.0.0:8000/` in a browser fails with
> `ERR_ADDRESS_INVALID (-108)`. Use `127.0.0.1:8000` to reach it from the same
> machine and your LAN IP (`ipconfig`) to reach it from a phone.

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

## Android app — the server is inside the APK

The APK is **self-contained**. The Django backend is bundled into it with
[Chaquopy](https://chaquo.com/chaquopy), so there is nothing to install or start on
the phone:

- Opening the app starts CPython in the app's own process, unpacks the demo
  catalogue, and binds the API on `http://127.0.0.1:8765/api/`.
- Closing the app ends the process, so the server stops with it. There is no
  separate process, service or notification to manage.
- The socket is loopback-only, so the API is unreachable from other devices.

The splash screen waits for `GET /api/health/` to answer before routing, and shows
a retry button if the boot fails.

### Why the first launch is quick

The demo catalogue is ~23 000 rows, 21 896 of them train berths. Seeding that on
the phone took tens of seconds, so it is done once at build time instead:

- `tools/build_seed_db.py` migrates a throwaway database, seeds it, compacts it and
  writes `tripgo_seed.sqlite3` (~2 MB) into the Chaquopy source root.
- On a first launch the launcher copies that file into app storage — a file copy,
  not 23 000 inserts — and only runs `migrate` afterwards, which is a no-op unless
  the app was updated with new migrations.
- `django.contrib.admin` is left out of `INSTALLED_APPS` in embedded mode, which
  roughly halves `django.setup()`. `/admin/` is not routed there; the desktop
  server is unaffected.

An existing database is never overwritten, so bookings survive an app update. If
the database was not bundled (no `backend/.venv` at build time) the launcher falls
back to seeding on device, which is slower but still correct.

How it fits together:

| Piece                                                            | Role                                            |
| ---------------------------------------------------------------- | ----------------------------------------------- |
| `frontend/android/app/src/main/python/tripgo_server.py`            | Binds the socket, migrates, seeds, serves WSGI   |
| `frontend/android/app/src/main/kotlin/…/TripGoServer.kt`           | Starts Python once per process, reports state   |
| `frontend/android/app/requirements-android.txt`                    | The pure-Python subset bundled into the APK      |
| `frontend/android/app/build.gradle.kts`                            | Syncs `backend/` + the seed DB into Chaquopy     |
| `tools/build_seed_db.py`                                           | Builds the pre-seeded database for the APK       |
| `frontend/lib/core/network/api_bootstrap.dart`                     | Resolves the port, gates the app on readiness    |

`backend/` is the single source of truth: Gradle copies it into the Chaquopy
source root on every build, so there is no duplicated copy to keep in sync. The
SQLite file and logs live in the app's private storage (`$HOME/tripgo`), not next
to the read-only APK assets.

### Build the APK

Double-click **`tripgo.bat`**. It prepares the Python env, checks the toolchain,
deletes the previous APK and builds a new one to
`frontend\build\app\outputs\flutter-apk\app-release.apk`.

Requirements: Flutter, Android SDK (platform 36, build-tools 36), JDK 17 and
**Python 3.13** — Chaquopy matches the bundled runtime to the build machine's
Python major.minor.

To verify the launch sequence without a device:

```bash
backend\.venv\Scripts\python tools\verify_embedded_server.py
backend\.venv\Scripts\python tools\verify_seed_bundle.py
```

---

## Flutter — quick start (web / desktop)

On Android the API is the embedded one, so there is nothing to configure. For the
web and desktop builds the Django server runs separately:

```bash
cd frontend
flutter pub get
flutter run                  # web uses http://127.0.0.1:8000/api/
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