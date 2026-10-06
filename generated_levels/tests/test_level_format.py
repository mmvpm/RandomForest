"""Tests for the editable single-map level format."""

from __future__ import annotations

import unittest

from generated_levels.procedural.level_format import decode_level, encode_level


class LevelFormatTests(unittest.TestCase):
    """Verify lossless conversion at the authoring/runtime boundary."""

    def test_wall_memories_survive_map_round_trip(self) -> None:
        """World-space text anchors must not consume or move gameplay map cells."""
        authored = {
            "width": 3,
            "height": 3,
            "map": ["...", ".@.", "###"],
            "wall_memories": [
                {
                    "id": "near_player",
                    "x": 12,
                    "y": 24,

                    "width": 90,
                    "role": "missing_previous",
                    "text": "Хватит.\nСтой.",
                    "min_collected": 2,
                    "requires_all_previous": False,
                }
            ],
        }

        rebuilt = encode_level(decode_level(authored))
        self.assertEqual(rebuilt["map"], authored["map"])
        self.assertEqual(rebuilt["wall_memories"], authored["wall_memories"])

    def test_semantic_layers_round_trip_through_one_editable_map(self) -> None:
        """Ground entities must display above their unchanged runtime anchors."""
        semantic = {
            "width": 5,
            "height": 4,
            "terrain": [
                ".....",
                ".....",
                "#####",
                "XXXXX",
            ],
            "hazards": [
                ".....",
                ".^...",
                ".....",
                ".....",
            ],
            "entities": [
                "O....",
                "...*.",
                "@.S..",
                ".....",
            ],
        }

        encoded = encode_level(semantic)

        self.assertEqual(
            encoded["map"],
            [
                "O....",
                "@^S*.",
                "#####",
                "XXXXX",
            ],
        )
        decoded = decode_level(encoded)
        for layer in ("terrain", "hazards", "entities"):
            self.assertEqual(decoded[layer], semantic[layer])

    def test_merge_rejects_two_symbols_in_one_editable_cell(self) -> None:
        """A raised ground entity must not replace another visible entity."""
        semantic = {
            "width": 2,
            "height": 3,
            "terrain": ["..", "..", "##"],
            "hazards": ["..", "..", ".."],
            "entities": ["..", "*.", "@."],
        }

        with self.assertRaisesRegex(ValueError, "overlaps"):
            encode_level(semantic)

    def test_decode_rejects_shared_runtime_entity_anchors(self) -> None:
        """Two visible cells must not decode to one gameplay anchor."""
        encoded = {
            "width": 2,
            "height": 3,
            "map": ["@.", "*.", "##"],
        }

        with self.assertRaisesRegex(ValueError, "runtime anchor|overlaps"):
            decode_level(encoded)


if __name__ == "__main__":
    unittest.main()
