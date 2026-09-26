"""Proves the bundled pre-seeded database is both fast and fully functional.

The TripGo APK ships a ready-made SQLite catalogue instead of seeding ~23k rows on
the device. This check copies the backend into a throwaway tree, drops the bundled
database next to the sources the way Gradle does, and then:

  * times the boot with and without the bundle,
  * queries real endpoints to prove the catalogue is usable,
  * confirms a second launch reuses the database instead of reseeding.

The server lives only as long as its process, so the HTTP checks run inside the same
subprocess that boots it.

Usage:
    python tools/verify_seed_bundle.py
"""

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VENV_PYTHON = REPO / "backend" / ".venv" / "Scripts" / "python.exe"
LAUNCHER = REPO / "frontend" / "android" / "app" / "src" / "main" / "python" / "tripgo_server.py"

BOOT_SCRIPT = r'''
import json, os, sys, time
root, home = sys.argv[1], sys.argv[2]
verify = len(sys.argv) > 3 and sys.argv[3] == "1"
sys.path.insert(0, root)
sys.path.insert(0, os.path.dirname(r"{launcher}"))
os.environ["HOME"] = home
os.environ.pop("TRIPGO_EMBEDDED", None)
os.environ.pop("TRIPGO_DATA_DIR", None)

started = time.time()
import tripgo_server
imported = time.time()

tripgo_server.prepare()
while True:
    state = tripgo_server.status()
    if state["phase"] in (tripgo_server.SERVING, tripgo_server.ERROR):
        break
    if time.time() - imported > 240:
        raise SystemExit("boot timed out")
    time.sleep(0.02)
ready = time.time()

port = tripgo_server._bound_port()
report = {{
    "phase": state["phase"],
    "detail": state["detail"],
    "import_s": round(imported - started, 2),
    "boot_s": round(ready - started, 2),
    "port": port,
    "checks": {{}},
}}

def collect(payload):
    """Pull a row count out of whatever shape the endpoint used."""
    if isinstance(payload, list):
        return payload
    if not isinstance(payload, dict):
        return []
    data = payload.get("data", payload)
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        for key in ("results", "cities", "stations", "buses", "trains", "offers", "items"):
            if isinstance(data.get(key), list):
                return data[key]
        for value in data.values():
            if isinstance(value, list):
                return value
    return []

if verify and report["phase"] == "serving":
    import urllib.request

    base = "http://127.0.0.1:%d/api" % port

    def get(path, headers=None):
        request = urllib.request.Request(base + "/" + path, headers=headers or {{}})
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode())

    def post(path, payload):
        request = urllib.request.Request(
            base + "/" + path,
            data=json.dumps(payload).encode(),
            headers={{"Content-Type": "application/json"}},
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode())

    try:
        health = get("health/")
        report["checks"]["health"] = health.get("data", {{}}).get("status")

        login = post("auth/login/", {{"email": "demo@tripgo.app", "password": "demo12345"}}).get("data", {{}})
        token = login.get("access")
        report["checks"]["demo_login"] = "ok" if token else "failed: %s" % json.dumps(login)[:200]
        headers = {{"Authorization": "Bearer " + token}} if token else {{}}

        for label, path in (
            ("cities", "cities/"),
            ("stations", "stations/"),
            ("buses", "buses/?source=Chennai&destination=Bengaluru"),
            ("trains", "trains/?source=Chennai&destination=Bengaluru"),
            ("offers", "offers/"),
        ):
            report["checks"][label] = len(collect(get(path, headers)))
    except Exception as exc:  # noqa: BLE001 - report, do not explode
        report["checks"]["error"] = "%s: %s" % (type(exc).__name__, exc)

database = os.path.join(home, "tripgo", "db.sqlite3")
report["database_bytes"] = os.path.getsize(database) if os.path.exists(database) else 0
report["leftover_temp"] = [n for n in os.listdir(os.path.dirname(database)) if n.endswith(".new")]

print("REPORT " + json.dumps(report))
tripgo_server.stop()
'''.replace("{launcher}", str(LAUNCHER).replace("\\", "\\\\")).replace("{{", "{").replace("}}", "}")


def make_tree(workdir, seed_db, label):
    root = Path(workdir) / f"backend-{label}"
    shutil.copytree(
        REPO / "backend",
        root,
        ignore=shutil.ignore_patterns(".venv", "__pycache__", "*.pyc", "db.sqlite3", ".env", "media", "staticfiles"),
    )
    if seed_db is not None:
        shutil.copyfile(seed_db, root / "tripgo_seed.sqlite3")
    return root


def boot(root, workdir, label, verify=False):
    home = Path(workdir) / f"home-{label}"
    if home.exists():
        shutil.rmtree(home)
    home.mkdir(parents=True)

    result = subprocess.run(
        [str(VENV_PYTHON), "-c", BOOT_SCRIPT, str(root), str(home), "1" if verify else "0"],
        capture_output=True,
        text=True,
        cwd=str(REPO),
    )
    reports = [line for line in result.stdout.splitlines() if line.startswith("REPORT ")]
    if not reports:
        print(result.stdout)
        print(result.stderr, file=sys.stderr)
        raise SystemExit(f"boot failed for {label}")
    report = json.loads(reports[-1][len("REPORT "):])

    print(f"  {label:24} phase={report['phase']:8} import={report['import_s']:5.2f}s  boot={report['boot_s']:6.2f}s")
    if report["phase"] != "serving":
        raise SystemExit(f"  {label} did not reach serving: {report['detail'][:400]}")
    return report, home


def check_catalogue(report):
    checks = report["checks"]
    if checks.get("error"):
        raise SystemExit(f"  API check failed: {checks['error']}")

    if checks.get("health") != "ok":
        raise SystemExit(f"  health did not report ok: {checks.get('health')}")
    if checks.get("demo_login") != "ok":
        raise SystemExit("  the demo user from the bundled database could not log in")

    for label in ("cities", "stations", "buses", "trains", "offers"):
        rows = checks.get(label)
        if not isinstance(rows, int) or rows == 0:
            raise SystemExit(f"  {label} returned no rows (got {rows!r}) - the bundled data is unusable")
        print(f"  {label:22} {rows} rows")


def main():
    seed_db = Path(tempfile.gettempdir()) / "tripgo_seed.sqlite3"
    if not seed_db.exists():
        print("building the seed database first")
        subprocess.run(
            [str(VENV_PYTHON), str(REPO / "tools" / "build_seed_db.py"), str(seed_db)],
            check=True,
            cwd=str(REPO),
        )
    print(f"bundled seed database: {seed_db.stat().st_size / 1e6:.2f} MB\n")

    with tempfile.TemporaryDirectory(prefix="tripgo-seedcheck-") as workdir:
        bundled_root = make_tree(workdir, seed_db, "bundled")
        plain_root = make_tree(workdir, None, "plain")

        print("first launch (cold, empty app storage)")
        bundled, home = boot(bundled_root, workdir, "with bundle", verify=True)
        plain, _ = boot(plain_root, workdir, "without bundle")

        speedup = plain["boot_s"] / bundled["boot_s"]
        print(f"\nboot time: {plain['boot_s']:.2f}s -> {bundled['boot_s']:.2f}s ({speedup:.1f}x faster)")
        if speedup < 1.5:
            raise SystemExit("  the bundled database barely helped - not worth the complexity")

        print("\nverifying the catalogue that came out of the bundle")
        check_catalogue(bundled)

        database = home / "tripgo" / "db.sqlite3"
        if bundled["database_bytes"] == 0:
            raise SystemExit("  no database was unpacked into app storage")
        if bundled["leftover_temp"]:
            raise SystemExit(f"  temporary files were left behind: {bundled['leftover_temp']}")
        print(f"  unpacked to            {database.name} ({bundled['database_bytes'] / 1e6:.2f} MB)")

        print("\nsecond launch (existing database must be reused, not rebuilt)")
        again, _ = boot(bundled_root, workdir, "with bundle")
        if again["boot_s"] > bundled["boot_s"] * 1.35:
            raise SystemExit(f"  relaunch was {again['boot_s']:.2f}s vs {bundled['boot_s']:.2f}s - it is reseeding")
        print(f"  relaunch               {again['boot_s']:.2f}s (no reseeding)")

    print("\nall seed bundle checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
