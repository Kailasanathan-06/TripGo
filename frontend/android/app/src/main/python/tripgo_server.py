"""TripGo in-app backend.

This module is the entry point of the Django backend that ships inside the TripGo
APK. The Android host (MainActivity) imports it through Chaquopy and calls
``prepare()`` as soon as the activity is created, so the server is already warming
up while Flutter renders its splash screen.

Lifecycle
---------
CPython runs *inside* the app process, therefore the server's lifetime is bound to
the app's lifetime without any extra bookkeeping: it starts when the process does
and disappears with it. ``stop()`` only exists so the activity can shut the socket
down cleanly when it is destroyed.

The socket is bound on the loopback interface only, so the API is unreachable from
outside the device.
"""

import os
import shutil
import socketserver
import sys
import threading
import traceback
from pathlib import Path
from wsgiref.simple_server import WSGIRequestHandler, WSGIServer, make_server

HOST = "127.0.0.1"
PREFERRED_PORT = 8765
PORT_SCAN_COUNT = 24

# Name of the pre-seeded database built by tools/build_seed_db.py and bundled as a
# Python data file next to the backend sources.
SEED_DB_NAME = "tripgo_seed.sqlite3"

IDLE = "idle"
WARMING = "warming"
SERVING = "serving"
STOPPED = "stopped"
ERROR = "error"

_state = {"phase": IDLE, "detail": ""}
_server = None
_worker = None
_lock = threading.Lock()


def status():
    """Return the current server state. Consumed by the Dart boot sequence."""
    return {"phase": _state["phase"], "detail": _state["detail"]}


def prepare(port=PREFERRED_PORT, host=HOST):
    """Bind the loopback socket and warm Django up on a background thread.

    Returns as soon as the port is known, so the caller never has to wait for the
    slow parts (asset extraction, imports, migrations, demo seed). Poll ``status()``
    until the phase turns into ``serving``.
    """
    global _server, _worker

    with _lock:
        if _state["phase"] in (WARMING, SERVING):
            return _bound_port()
        _set_phase(WARMING, "Starting in-app server")
        _configure_environment()
        # Only the bind happens here. Importing Django and touching the database are
        # the slow parts and they belong on the worker, so this returns in
        # milliseconds and the port is known straight away.
        application = _LazyApp()
        _server = _create_server(host, port, application)
        bound = _bound_port()
        server = _server
        _worker = threading.Thread(
            target=_run, args=(server, application), name="tripgo-server", daemon=True
        )
        worker = _worker

    worker.start()
    return bound


def stop():
    """Close the loopback socket. The worker thread exits with the process."""
    global _server, _worker

    with _lock:
        server, _server = _server, None
        worker, _worker = _worker, None
        if server is None:
            return False
        _set_phase(STOPPED, "")

    # Wait for the socket to actually close. Returning early would let a following
    # prepare() rebind the port while this socket is still open, and on platforms
    # where SO_REUSEADDR permits that (Windows) the pending connection can be handed
    # to the closing socket and reset. This matters when the activity is recreated.
    if worker is not None and worker.is_alive() and worker is not threading.current_thread():
        if getattr(server, "tripgo_serving", False):
            server.shutdown()
            worker.join(timeout=3)
        else:
            # Still warming up, so serve_forever() never ran. Join without asking it to
            # shut down; it checks the phase and bails out on its own.
            worker.join(timeout=3)
    try:
        server.server_close()
    except Exception:  # noqa: BLE001 - best effort cleanup
        pass
    return True


def _bound_port():
    return _server.server_address[1] if _server is not None else 0


def _set_phase(phase, detail):
    _state["phase"] = phase
    _state["detail"] = detail


def _configure_environment():
    """Point Django at writable app storage instead of the read-only APK assets."""
    home = os.environ.get("HOME") or "/data/data/com.example.tripgo/files"
    data_dir = os.path.join(home, "tripgo")
    os.makedirs(data_dir, exist_ok=True)

    os.environ["TRIPGO_EMBEDDED"] = "1"
    os.environ["TRIPGO_DATA_DIR"] = data_dir
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
    os.environ.setdefault("TZ", "Asia/Kolkata")


def _install_bundled_database(data_dir):
    """Seed the writable database from the copy bundled in the APK.

    Returns True when the bundled catalogue was unpacked. This replaces seeding ~23k
    rows on the device, which dominated the start-up time. An existing database is
    never touched, so anything the user has done in the app survives an app update.
    """
    target = Path(data_dir) / "db.sqlite3"
    if target.exists():
        return False

    source = _bundled_seed_db()
    if source is None:
        return False

    temporary = target.with_suffix(".sqlite3.new")
    shutil.copyfile(source, temporary)
    os.replace(temporary, target)
    return True


def _bundled_seed_db():
    """Locate the seed database inside the extracted APK assets, if it is there."""
    try:
        # Imported directly rather than through the settings machinery: config.settings
        # only needs os/pathlib/dotenv, so this stays cheap and needs no django.setup().
        # Its BASE_DIR is the Python source root, which is where Gradle put the file.
        from config.settings import BASE_DIR
    except ImportError:
        return None

    candidate = Path(BASE_DIR) / SEED_DB_NAME
    return candidate if candidate.is_file() else None


class _QuietRequestHandler(WSGIRequestHandler):
    """wsgiref logs every request to stderr; the app's own logger is enough."""

    def log_message(self, fmt, *args):
        pass


class _ThreadingWSGIServer(socketserver.ThreadingMixIn, WSGIServer):
    """One thread per request so a slow query cannot block the whole API."""

    daemon_threads = True
    allow_reuse_address = True
    request_queue_size = 32


class _LazyApp:
    """Binds the socket now, imports Django on the worker thread.

    ``prepare()`` has to return the port promptly because the Android host calls into
    Python under a lock that ``status()`` also needs, so a multi-second import inside
    it would stall every poll. Requests that arrive early wait on the event instead of
    seeing a half-built application.
    """

    def __init__(self):
        self._application = None
        self._ready = threading.Event()

    def build(self):
        self._application = _wsgi_app()
        self._ready.set()
        return self._application

    def __call__(self, environ, start_response):
        self._ready.wait()
        return self._application(environ, start_response)


def _create_server(host, preferred_port, application):
    last_error = None
    for offset in range(PORT_SCAN_COUNT):
        port = preferred_port + offset
        try:
            return make_server(
                host,
                port,
                application,
                server_class=_ThreadingWSGIServer,
                handler_class=_QuietRequestHandler,
            )
        except OSError as exc:
            last_error = exc
    raise OSError(
        f"no free port in {host}:{preferred_port}-{preferred_port + PORT_SCAN_COUNT - 1} ({last_error})"
    )


def _wsgi_app():
    try:
        import django
    except ImportError as exc:  # pragma: no cover - only on a broken packaging
        raise RuntimeError("Django is missing from the APK payload") from exc

    try:
        django.setup()
        from config.wsgi import application
    except ImportError as exc:
        raise RuntimeError(
            "the TripGo backend package is missing from the APK; rebuild the project so "
            "Gradle can sync backend/ into the Chaquopy source set"
        ) from exc

    return application


def _run(server, application):
    global _server

    try:
        application.build()
        _bootstrap_database()
        with _lock:
            if _state["phase"] != WARMING:
                return
            _set_phase(SERVING, "")
        print(f"[tripgo] API listening on http://{HOST}:{_bound_port()}/api/")
        # Lets stop() tell whether shutdown() is safe to call: BaseServer.shutdown()
        # waits on an event that serve_forever() only sets, so calling it before this
        # point would block the caller forever.
        server.tripgo_serving = True
        server.serve_forever(poll_interval=0.5)
    except BaseException:  # noqa: BLE001 - the state dict is the error channel
        detail = traceback.format_exc()
        with _lock:
            # A stop() that landed mid-warm-up is not a failure worth reporting.
            if _state["phase"] != STOPPED:
                _set_phase(ERROR, detail)
        print(f"[tripgo] server failed:\n{detail}")
    finally:
        with _lock:
            if _server is server:
                _server = None
        try:
            server.server_close()
        except Exception:  # noqa: BLE001 - best effort cleanup
            pass


def _bootstrap_database():
    """Create the schema and, on a fresh install, load the demo catalogue."""
    from django.core.management import call_command

    data_dir = os.environ.get("TRIPGO_DATA_DIR", "")
    if _install_bundled_database(data_dir):
        # The catalogue came out of the APK, so the only work left is making sure the
        # schema matches this build. That is a no-op unless the app was updated.
        _report("Unpacking bundled catalogue")
        call_command("migrate", interactive=False, verbosity=0)
        _report("Starting API")
        return

    _report("Applying database migrations")
    call_command("migrate", interactive=False, verbosity=0)

    # Demo data is only loaded while the catalogue is empty, so bookings a user has
    # already made are never wiped on a later launch. This is the slow path, used when
    # the pre-seeded database was not bundled into the APK.
    _report("Loading demo data")
    call_command("seed_demo_data", if_empty=True, verbosity=0)

    _report("Starting API")


def _report(detail):
    with _lock:
        _state["detail"] = detail
    print(f"[tripgo] {detail}")


def log(message):
    """Small helper so the Android host can annotate the Logcat timeline."""
    print(f"[tripgo] {message}")
    sys.stdout.flush()
