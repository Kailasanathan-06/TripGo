"""Desktop harness for the in-app server.

Runs frontend/android/app/src/main/python/tripgo_server.py on a normal CPython
interpreter against the real backend, so the launch sequence (bind -> migrate ->
seed -> serve) and the health endpoint can be verified without a device.

Usage:
    python tools/verify_embedded_server.py
"""

import json
import os
import shutil
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LAUNCHER = REPO / "frontend" / "android" / "app" / "src" / "main" / "python" / "tripgo_server.py"
BACKEND = REPO / "backend"

sys.path.insert(0, str(LAUNCHER.parent))
sys.path.insert(0, str(BACKEND))


def http_get(url, timeout=3):
    with urllib.request.urlopen(url, timeout=timeout) as response:
        return response.status, json.loads(response.read().decode())


def wait_for_serving(deadline_seconds=180):
    deadline = time.time() + deadline_seconds
    last = None
    while time.time() < deadline:
        last = tripgo_server.status()
        if last["phase"] in (tripgo_server.SERVING, tripgo_server.ERROR):
            return last
        time.sleep(0.25)
    raise AssertionError(f"server never finished warming up (last status: {last})")


def main():
    global tripgo_server

    data_dir = Path(tempfile.mkdtemp(prefix="tripgo-embedded-"))
    os.environ["HOME"] = str(data_dir)
    print(f"data dir: {data_dir}")

    import tripgo_server

    started = time.time()
    port = tripgo_server.prepare()
    print(f"bound 127.0.0.1:{port} after {time.time() - started:.2f}s")

    status = wait_for_serving()
    print(f"status: {status['phase']} ({time.time() - started:.2f}s)")
    if status["phase"] != tripgo_server.SERVING:
        raise AssertionError(f"server failed to start:\n{status['detail']}")

    base = f"http://127.0.0.1:{port}/api/"
    code, body = http_get(f"{base}health/")
    assert code == 200, (code, body)
    assert body["data"]["status"] == "ok", body
    print(f"health: {code} {body['data']}")

    # The schema and the demo catalogue must both be in place by now. The launcher
    # puts everything under $HOME/tripgo, never next to the read-only APK assets.
    database = data_dir / "tripgo" / "db.sqlite3"
    assert database.exists(), f"sqlite file was not created at {database}"

    request = urllib.request.Request(
        f"{base}auth/login/",
        data=json.dumps({"email": "demo@tripgo.app", "password": "demo12345"}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=15) as response:
        code = response.status
        body = json.loads(response.read().decode())
    assert code == 200, (code, body)
    assert body["data"]["access"], body
    print(f"login: {code}, access token issued")

    # A second boot must reuse the existing database instead of re-seeding it.
    tripgo_server.stop()
    print("stopped")

    tripgo_server._state.update(phase=tripgo_server.IDLE, detail="")
    port_again = tripgo_server.prepare()
    status_again = wait_for_serving()
    assert status_again["phase"] == tripgo_server.SERVING, status_again
    print(f"restart: 127.0.0.1:{port_again}, phase={status_again['phase']}")
    code, body = http_get(f"http://127.0.0.1:{port_again}/api/health/")
    assert code == 200, (code, body)
    print(f"health after restart: {code} {body['data']}")

    tripgo_server.stop()
    print("\nAll embedded-server checks passed.")
    shutil.rmtree(data_dir, ignore_errors=True)


if __name__ == "__main__":
    main()
