"""Serve the level visualizer and save edits to existing challenge JSON files."""

from __future__ import annotations

import os
import re
import tempfile
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit


PROJECT_ROOT = Path(__file__).resolve().parents[1]
LEVEL_DIRECTORY = PROJECT_ROOT / "RandomForest" / "datafiles" / "challenge_levels"
LEVEL_PATH_PATTERN = re.compile(r"^/api/levels/(?P<file_name>\d+\.json)$")


class LevelEditorHandler(SimpleHTTPRequestHandler):
    """Serve project files and accept writes only for existing numbered levels."""

    # Reports save capability without reading or modifying a level.
    def do_GET(self) -> None:
        if urlsplit(self.path).path != "/api/status":
            super().do_GET()
            return

        contents = b'{"can_save":true}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(contents)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(contents)

    # Allows PUT requests from a VS Code HTML preview.
    def do_OPTIONS(self) -> None:
        if not LEVEL_PATH_PATTERN.fullmatch(unquote(urlsplit(self.path).path)):
            self.send_error(404)
            return

        self.send_response(204)
        self.end_headers()

    # Saves a numbered challenge level without interpreting its contents.
    def do_PUT(self) -> None:
        request_path = unquote(urlsplit(self.path).path)
        match = LEVEL_PATH_PATTERN.fullmatch(request_path)
        if not match:
            self.send_error(404)
            return

        target = LEVEL_DIRECTORY / match.group("file_name")
        if not target.is_file():
            self.send_error(404)
            return

        try:
            content_length = int(self.headers["Content-Length"])
        except (KeyError, TypeError, ValueError):
            self.send_error(411)
            return

        try:
            self._replace_file(target, self.rfile.read(content_length))
        except OSError as error:
            self.send_error(500, str(error))
            return

        self.send_response(204)
        self.end_headers()

    # Adds the headers required by VS Code webview cross-origin requests.
    def end_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, PUT, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()

    # Replaces the target atomically while preserving its file permissions.
    def _replace_file(self, target: Path, contents: bytes) -> None:
        descriptor, temporary_name = tempfile.mkstemp(
            prefix=f".{target.name}.",
            dir=target.parent,
        )
        temporary_path = Path(temporary_name)
        try:
            with os.fdopen(descriptor, "wb") as temporary_file:
                temporary_file.write(contents)
            temporary_path.chmod(target.stat().st_mode)
            temporary_path.replace(target)
        finally:
            temporary_path.unlink(missing_ok=True)


# Starts the project-local HTTP server on the loopback interface.
def main() -> None:
    """Serve the visualizer until interrupted."""
    handler = partial(LevelEditorHandler, directory=str(PROJECT_ROOT))
    server = ThreadingHTTPServer(("127.0.0.1", 8000), handler)
    print("Level visualizer save server: http://127.0.0.1:8000")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
