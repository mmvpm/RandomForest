"""Check authored-colony metadata without imposing new gameplay geometry rules."""

import copy
import unittest

from generated_levels.procedural.level_format import decode_level, encode_level
from generated_levels.procedural.moth_nests import validate_moth_nests


class MothNestTests(unittest.TestCase):
    """Protect authoring boundaries and optional-field round trips."""

    def level(self):
        """Provide a small map whose black mass deliberately has no collision semantics."""
        return {"width": 6, "height": 5, "map": ["XXXXXX", "X....X", "X....X", "X####X", "XXXXXX"]}

    def test_round_trip_preserves_metadata_and_map(self):
        """Changing visual anchors must never rewrite the ASCII gameplay layer."""
        level = self.level()
        level["moth_nests"] = [{"id":"a","x":30,"y":24,"count":30,"radius":65}]
        validate_moth_nests(level)
        self.assertEqual(encode_level(decode_level(level)),level)
        plain = self.level()
        validate_moth_nests(plain)
        self.assertNotIn("moth_nests",plain)

    def test_black_fill_and_invalid_colonies_are_rejected(self):
        """Validate visual occupancy, bounded populations and stable author IDs."""
        level = self.level()
        level["moth_nests"] = [{"id":"a","x":30,"y":24}]
        for patch in ({"x":0},{"y":0},{"count":100},{"radius":100},{"x":float("nan")}):
            invalid=copy.deepcopy(level);invalid["moth_nests"][0].update(patch)
            with self.assertRaises(ValueError):validate_moth_nests(invalid)
        invalid=copy.deepcopy(level);invalid["moth_nests"]*=2
        with self.assertRaises(ValueError):validate_moth_nests(invalid)


if __name__ == "__main__":unittest.main()
