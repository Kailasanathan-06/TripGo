"""Builds the pre-seeded SQLite database that is bundled into the TripGo APK.

Seeding the demo catalogue writes ~23k rows (21.9k of them train berths), which
takes seconds on a build machine and far longer on a phone. Doing it once at build
time and shipping the resulting file turns the first launch into a plain file copy.

The database is written in rollback-journal mode with a truncated WAL so it is a
single self-contained file with no sidecars.

Usage:
    python tools/build_seed_db.py <output.sqlite3> [--backend <dir>]
"""

import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DEFAULT_BACKEND = REPO / "backend"


def run(venv_python, backend, *args):
    env = dict(os.environ)
    env.pop("TRIPGO_EMBEDDED", None)
    result = subprocess.run(
        [str(venv_python), "manage.py", *args],
        cwd=str(backend),
        env=env,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise SystemExit(f"manage.py {' '.join(args)} failed:\n{result.stdout}\n{result.stderr}")


def compact(source, destination):
    """Checkpoint the WAL and switch to rollback journals so the copy stands alone."""
    connection = sqlite3.connect(str(source))
    try:
        connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        connection.execute("PRAGMA journal_mode=DELETE")
        connection.execute("VACUUM")
        connection.commit()
    finally:
        connection.close()

    shutil.copyfile(source, destination)
    for suffix in ("-wal", "-shm"):
        stale = Path(str(source) + suffix)
        if stale.exists():
            stale.unlink()


def main(argv):
    if len(argv) < 2:
        raise SystemExit(__doc__)

    destination = Path(argv[1]).resolve()
    backend = Path(argv[3]).resolve() if len(argv) > 3 and argv[2] == "--backend" else DEFAULT_BACKEND

    venv_python = backend / ".venv" / "Scripts" / "python.exe"
    if not venv_python.exists():
        venv_python = backend / ".venv" / "bin" / "python"
    if not venv_python.exists():
        print(f"no virtualenv at {backend / '.venv'}", file=sys.stderr)
        return 1

    destination.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="tripgo-seed-") as workdir:
        data_dir = Path(workdir) / "data"
        data_dir.mkdir()

        env_backup = os.environ.get("TRIPGO_DATA_DIR")
        os.environ["TRIPGO_DATA_DIR"] = str(data_dir)
        os.environ["TRIPGO_EMBEDDED"] = "1"
        try:
            run(venv_python, backend, "migrate", "--noinput", "--verbosity", "0")
            run(venv_python, backend, "seed_demo_data", "--verbosity", "0")
        finally:
            if env_backup is None:
                os.environ.pop("TRIPGO_DATA_DIR", None)
            else:
                os.environ["TRIPGO_DATA_DIR"] = env_backup
            os.environ.pop("TRIPGO_EMBEDDED", None)

        produced = data_dir / "db.sqlite3"
        if not produced.exists():
            raise SystemExit("migrate/seed did not produce a database")
        compact(produced, destination)

    size_mb = destination.stat().st_size / 1e6
    print(f"seed database written: {destination} ({size_mb:.2f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
