"""Check the editor HTTP API against temporary levels, never game data."""

import importlib.util
import json
import tempfile
import threading
import unittest
from functools import partial
from http.server import ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen


spec = importlib.util.spec_from_file_location("editor_server", Path(__file__).parents[1] / "server.py")
server_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server_module)


class EditorServerTests(unittest.TestCase):
    """Exercise health, cross-origin saves and restricted write paths over HTTP."""

    def setUp(self):
        """Start a loopback server with a disposable fixture directory."""
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        self.level = self.root / "11.json"
        self.level.write_text('{"map":["X"]}', encoding="utf-8")
        self.original_directory = server_module.LEVEL_DIRECTORY
        server_module.LEVEL_DIRECTORY = self.root
        handler = partial(server_module.LevelEditorHandler, directory=str(self.root))
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.url = f"http://127.0.0.1:{self.server.server_port}"

    def tearDown(self):
        """Stop the server and restore its real level directory."""
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()
        server_module.LEVEL_DIRECTORY = self.original_directory
        self.directory.cleanup()

    def test_health_and_cross_origin_save(self):
        """Verify Preview HTML can discover the API and save a complete level."""
        with urlopen(self.url + "/api/status") as response:
            self.assertEqual(json.load(response), {"can_save": True})
            self.assertEqual(response.headers["Access-Control-Allow-Origin"], "*")
            self.assertEqual(response.headers["Cache-Control"], "no-store")
        request = Request(self.url + "/api/levels/11.json", method="OPTIONS", headers={
            "Origin": "vscode-webview://preview", "Access-Control-Request-Method": "PUT",
            "Access-Control-Request-Headers": "content-type"})
        with urlopen(request) as response:
            self.assertEqual(response.status, 204)
            self.assertIn("PUT", response.headers["Access-Control-Allow-Methods"])
            self.assertEqual(response.headers["Access-Control-Allow-Headers"], "Content-Type")
        contents = '{"map":["X"],"wall_memories":[{"id":"memory_1","x":30}]}'.encode()
        request = Request(self.url + "/api/levels/11.json", data=contents, method="PUT",
                          headers={"Content-Type": "application/json; charset=utf-8"})
        mode = self.level.stat().st_mode
        with urlopen(request) as response:
            self.assertEqual(response.status, 204)
        self.assertEqual(self.level.read_bytes(), contents)
        self.assertEqual(self.level.stat().st_mode, mode)
        with urlopen(self.url + "/11.json") as response:
            self.assertEqual(response.read(), contents)

    def test_write_restrictions(self):
        """Reject new files and paths outside existing numbered levels."""
        original = self.level.read_bytes()
        for path in ["/api/levels/99.json", "/api/levels/catalog.json", "/api/levels/../11.json"]:
            with self.assertRaises(HTTPError) as error:
                urlopen(Request(self.url + path, data=b"changed", method="PUT"))
            self.assertEqual(error.exception.code, 404)
            error.exception.close()
        self.assertEqual(self.level.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
