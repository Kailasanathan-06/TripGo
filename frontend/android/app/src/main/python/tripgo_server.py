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
import socketserver
import sys
import threading
import traceback
from wsgiref.simple_server import WSGIRequestHandler, WSGIServer, make_server

HOST = "127.0.0.1"
PREFERRED_PORT = 8765
PORT_SCAN_COUNT = 24

IDLE = "idle"
WARMING = "warming"
SERVING = "serving"
STOPPED = "stopped"
ERROR = "error"

_state = {"phase": IDLE, "detail": ""}
_server = None
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
    global _server

    with _lock:
        if _state["phase"] in (WARMING, SERVING):
            return _bound_port()
        _set_phase(WARMING, "Starting in-app server")
        _configure_environment()
        _server = _create_server(host, port)
        bound = _bound_port()
        server = _server

    threading.Thread(target=_run, args=(server,), name="tripgo-server", daemon=True).start()
    return bound


def stop():
    """Close the loopback socket. The worker thread exits with the process."""
    global _server

    with _lock:
        server, _server = _server, None
        if server is None:
            return False
        _set_phase(STOPPED, "")

    threading.Thread(target=server.shutdown, name="tripgo-shutdown", daemon=True).start()
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


class _QuietRequestHandler(WSGIRequestHandler):
    """wsgiref logs every request to stderr; the app's own logger is enough."""

    def log_message(self, fmt, *args):
        pass


class _ThreadingWSGIServer(socketserver.ThreadingMixIn, WSGIServer):
    """One thread per request so a slow query cannot block the whole API."""

    daemon_threads = True
    allow_reuse_address = True
    request_queue_size = 32


def _create_server(host, preferred_port):
    application = _wsgi_app()
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


def _run(server):
    global _server

    try:
        _bootstrap_database()
        with _lock:
            if _state["phase"] != WARMING:
                return
            _set_phase(SERVING, "")
        print(f"[tripgo] API listening on http://{HOST}:{_bound_port()}/api/")
        server.serve_forever(poll_interval=0.5)
    except BaseException:  # noqa: BLE001 - the state dict is the error channel
        detail = traceback.format_exc()
        with _lock:
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

    _report("Applying database migrations")
    call_command("migrate", interactive=False, verbosity=0)

    # Demo data is only loaded while the catalogue is empty, so bookings a user has
    # already made are never wiped on a later launch.
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
