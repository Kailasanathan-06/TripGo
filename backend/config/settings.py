import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

# When the backend is embedded in the TripGo Android app, the Python code is read
# straight out of the APK and is therefore read-only. TRIPGO_DATA_DIR is pointed at
# the app's private storage so the SQLite file and logs have a writable home.
DATA_DIR = Path(os.getenv("TRIPGO_DATA_DIR") or BASE_DIR)
DATA_DIR.mkdir(parents=True, exist_ok=True)

# Set by the in-app launcher. The server only ever listens on the loopback
# interface, so it is unreachable from the network.
EMBEDDED = os.getenv("TRIPGO_EMBEDDED", "") == "1"

SECRET_KEY = os.getenv("SECRET_KEY", "dev-insecure-change-me")
DEBUG = False if EMBEDDED else os.getenv("DEBUG", "True").lower() == "true"
ALLOWED_HOSTS = [h.strip() for h in os.getenv("ALLOWED_HOSTS", "localhost,127.0.0.1,10.0.2.2").split(",") if h.strip()]
if EMBEDDED:
    ALLOWED_HOSTS = ["127.0.0.1", "localhost", "10.0.2.2", "[::1]"]

INSTALLED_APPS = [
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",
    "apps.accounts",
    "apps.cities",
    "apps.buses",
    "apps.trains",
    "apps.bookings",
    "apps.payments",
    "apps.tickets",
    "apps.offers",
    "apps.notifications",
]

if not EMBEDDED:
    # django.contrib.admin drags in the whole ModelAdmin/form machinery and roughly
    # doubles django.setup(). The in-app server never serves /admin/, so it is left
    # out there; the desktop server keeps the full admin site.
    INSTALLED_APPS.insert(0, "django.contrib.admin")

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": DATA_DIR / "db.sqlite3",
        "OPTIONS": {
            # The in-app server is threaded, so let SQLite wait for a lock instead
            # of raising "database is locked", and use WAL for concurrent readers.
            "timeout": 20,
            "init_command": "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;",
        },
    }
}

DATABASE_URL = os.getenv("DATABASE_URL")
if DATABASE_URL:
    # Supports: postgres://user:pass@host:5432/dbname
    import re

    m = re.match(r"postgres(?:ql)?://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)", DATABASE_URL)
    if m:
        DATABASES["default"] = {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": m.group(5),
            "USER": m.group(1),
            "PASSWORD": m.group(2),
            "HOST": m.group(3),
            "PORT": m.group(4),
        }

AUTH_USER_MODEL = "accounts.User"
AUTH_PASSWORD_VALIDATORS = []

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Asia/Kolkata"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    "EXCEPTION_HANDLER": "apps.common.exceptions.api_exception_handler",
}

from datetime import timedelta  # noqa: E402

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(hours=12),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
}

CORS_ALLOWED_ORIGINS = [
    o.strip()
    for o in os.getenv(
        "CORS_ALLOWED_ORIGINS",
        "http://localhost:8000,http://127.0.0.1:8000,http://10.0.2.2:8000",
    ).split(",")
    if o.strip()
]
CORS_ALLOW_CREDENTIALS = True

# Seat hold duration in minutes before a HELD seat is released.
SEAT_HOLD_MINUTES = int(os.getenv("SEAT_HOLD_MINUTES", "15"))