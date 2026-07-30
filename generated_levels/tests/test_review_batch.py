"""Tests for isolated procedural review artifacts."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from generated_levels.review_batch import (
    next_review_directory,
    write_review_html,
)


class ReviewBatchTests(unittest.TestCase):
    """Verify append-only review paths and standalone HTML embedding."""

    def test_next_review_directory_preserves_earlier_iterations(self) -> None:
        """A new review run must not overwrite a previous comparison."""
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "iteration-01").mkdir()
            (root / "iteration-03").mkdir()
            self.assertEqual(
                next_review_directory(root),
                root / "iteration-04",
            )

    def test_review_html_embeds_level_data(self) -> None:
        """The gallery must work directly from disk without fetch requests."""
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            template = root / "template.html"
            output = root / "index.html"
            template.write_text(
                "<script>const cards = __REVIEW_DATA__;</script>",
                encoding="utf-8",
            )
            cards = [{"file_name": "01.json", "level": {"width": 2}}]
            write_review_html(output, template, cards)
            contents = output.read_text(encoding="utf-8")
            self.assertIn(json.dumps(cards, ensure_ascii=False), contents)
            self.assertNotIn("__REVIEW_DATA__", contents)


if __name__ == "__main__":
    unittest.main()
