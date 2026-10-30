"""Guard stable font builds and invalidate GameMaker's cached bitmap after a glyph change."""

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from theme_assets import read_resource


class WallFontBuilderTest(unittest.TestCase):
    """Exercise the builder on disposable copies of the actual sprite resource."""

    def setUp(self):
        """Copy reproducible inputs without altering production bitmaps or metadata."""
        self.work = tempfile.TemporaryDirectory(prefix="wall-font-")
        self.addCleanup(self.work.cleanup)
        self.project = Path(self.work.name)
        self.sprite = self.project / "sprites/sMemoryAlphabet"
        shutil.copytree(ROOT / "RandomForest/sprites/sMemoryAlphabet", self.sprite)
        (self.project / "datafiles/narrative").mkdir(parents=True)
        (self.project / "datafiles/fonts").mkdir()
        shutil.copyfile(ROOT / "RandomForest/datafiles/narrative/memory_font.json",
                        self.project / "datafiles/narrative/memory_font.json")

    def build(self):
        """Run the real command-line builder and return its resource references."""
        subprocess.run([sys.executable, str(ROOT / "tools/build_wall_memory_font.py"),
                        "--project-dir", str(self.project)], check=True, stdout=subprocess.DEVNULL)
        return read_resource(self.sprite / "sMemoryAlphabet.yy")

    def test_repeat_build_keeps_resource_identity(self):
        """An unchanged rebuild must not churn IDs or editor metadata."""
        first = self.build()
        content = (self.sprite / "sMemoryAlphabet.yy").read_bytes()
        self.assertEqual(first, self.build())
        self.assertEqual(content, (self.sprite / "sMemoryAlphabet.yy").read_bytes())

    def test_changed_bitmap_gets_a_new_frame_and_sequence_reference(self):
        """Changed pixels cannot silently reuse the old packed bitmap identity."""
        first = self.build()
        metadata = read_resource(self.project / "datafiles/narrative/memory_font.json")
        index = metadata["characters"].index("A")  # Preserve this legacy glyph rather than regenerating it.
        old = first["frames"][index]["name"]
        image = Image.open(self.sprite / f"{old}.png").convert("RGBA")
        image.putpixel((image.width - 1, image.height - 1), (255, 255, 255, 255))
        image.save(self.sprite / f"{old}.png")
        second = self.build()
        new = second["frames"][index]["name"]
        self.assertNotEqual(old, new)
        self.assertEqual([i for i, (a, b) in enumerate(zip(first["frames"], second["frames"])) if a != b], [index])
        key = second["sequence"]["tracks"][0]["keyframes"]["Keyframes"][index]
        self.assertEqual(key["Channels"]["0"]["Id"]["name"], new)
        self.assertFalse((self.sprite / f"{old}.png").exists())
        self.assertEqual(Image.open(self.sprite / f"{new}.png").convert("RGBA").tobytes(), image.tobytes())
        layer = second["layers"][0]["name"]
        self.assertEqual(Image.open(self.sprite / "layers" / new / f"{layer}.png").convert("RGBA").tobytes(), image.tobytes())


if __name__ == "__main__":
    unittest.main()
