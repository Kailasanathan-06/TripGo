#!/usr/bin/env python
"""Starts the TripGo API so a phone on the same Wi-Fi can reach it.

The Android build normally runs Django inside the APK, which needs no server at
all. This script is the alternative when that is too slow on a particular device:
the laptop serves the API and the app is pointed at it from the splash screen.

Binding to 0.0.0.0 is the part that matters. Django's development server only
listens on 127.0.0.1 by default, which is reachable from the laptop and from
nothing else, so the phone gets a connection refusal. The firewall is the other
common cause, and this script cannot open it - see the printed notes.
"""

import os
import socket
import subprocess
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parent.parent / "backend"
PORT = int(os.getenv("TRIPGO_PORT", "8000"))


def lan_address() -> str:
    """The address other devices would use to reach this machine.

    Connecting a UDP socket does not send anything, but it does make the OS pick
    the interface that would be used for outbound traffic, which is the one the
    phone shares. Reading the resolved hostname is unreliable on networks where
    DNS points somewhere else entirely.
    """
    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        probe.connect(("8.8.8.8", 80))
        return probe.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        probe.close()


def main() -> int:
    if not (BACKEND / "manage.py").exists():
        print(f"No manage.py in {BACKEND}", file=sys.stderr)
        return 1

    interpreter = BACKEND / ".venv" / "Scripts" / "python.exe"
    if not interpreter.exists():
        interpreter = BACKEND / ".venv" / "bin" / "python"
    if not Path(interpreter).exists():
        print("No virtualenv found. Create one with:", file=sys.stderr)
        print("  python -m venv backend/.venv", file=sys.stderr)
        print("  backend/.venv/Scripts/pip install -r backend/requirements-android.txt", file=sys.stderr)
        return 1

    address = lan_address()
    env = dict(os.environ)
    # Without this, Django rejects the phone's requests with DisallowedHost
    # because the Host header is the laptop's LAN address rather than localhost.
    env["TRIPGO_ALLOW_LAN"] = "1"

    print(f"  TripGo API listening on http://0.0.0.0:{PORT}")
    print(f"  Enter this on the phone:  {address}:{PORT}")
    print()
    print("  On the phone, tap the server address at the bottom of the splash screen.")
    print("  If the phone is on mobile data rather than Wi-Fi, this will not work;")
    print("  put both devices on the same network, or share the laptop's hotspot.")
    print("  Press Ctrl+C to stop.")
    print()

    return subprocess.call(
        [str(interpreter), "manage.py", "runserver", f"0.0.0.0:{PORT}", "--noreload"],
        cwd=str(BACKEND),
        env=env,
    )


if __name__ == "__main__":
    raise SystemExit(main())
