import os
import socket
import time
from datetime import datetime, timezone
from urllib.parse import urlparse


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _check_db_socket(database_url: str) -> bool:
    parsed = urlparse(database_url)
    host = parsed.hostname or "localhost"
    port = parsed.port or 5432
    try:
        with socket.create_connection((host, port), timeout=2):
            return True
    except OSError:
        return False


def main() -> None:
    interval = int(os.environ.get("WORKER_INTERVAL_SECONDS", "60"))
    database_url = os.environ.get("DATABASE_URL", "")
    print(f"[selfhost-worker] started (interval={interval}s)")
    while True:
        db_ok = _check_db_socket(database_url) if database_url else False
        print(f"[{_utc_now()}] selfhost worker heartbeat | db_socket_ok={db_ok}")
        time.sleep(interval)


if __name__ == "__main__":
    main()
