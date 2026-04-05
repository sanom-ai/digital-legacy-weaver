import json
import os
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


class Handler(BaseHTTPRequestHandler):
    def _reply(self, status: int, payload: dict) -> None:
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/health":
            self._reply(
                200,
                {
                    "ok": True,
                    "service": "selfhost-api",
                    "timestamp": _utc_now(),
                },
            )
            return
        self._reply(404, {"ok": False, "error": "Not found"})

    def do_POST(self) -> None:  # noqa: N802
        if self.path == "/v1/life-signal":
            self._reply(
                202,
                {
                    "ok": True,
                    "accepted": True,
                    "note": "Scaffold endpoint. Wire to database adapter in next iteration.",
                },
            )
            return
        self._reply(404, {"ok": False, "error": "Not found"})


def main() -> None:
    host = os.environ.get("SELFHOST_BIND", "0.0.0.0")
    port = int(os.environ.get("SELFHOST_PORT", "8080"))
    server = ThreadingHTTPServer((host, port), Handler)
    print(f"[selfhost-api] listening on http://{host}:{port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
