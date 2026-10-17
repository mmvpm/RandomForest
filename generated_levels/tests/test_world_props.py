"""Check authored group ownership, compatibility and six-pixel physical geometry."""

import copy
import unittest

from generated_levels.procedural.level_format import decode_level, encode_level
from generated_levels.procedural.placement import pixel_footprint_clear
from generated_levels.procedural.validation import _validate_entities
from generated_levels.procedural.world_props import has_support, prop_collision_cells, prop_solid_cells, prop_types


class WorldPropTests(unittest.TestCase):
    """Exercise the optional format and its collision-only contribution."""

    def setUp(self):
        """Create a small map with a two-cell platform owned by a single prop."""
        self.level = {"width": 10, "height": 10, "map": ["." * 10] * 10,
                      "props": [{"id": "table", "type": "morning_table", "x": 60, "y": 60,
                                 "mirrored": False, "solids": [[-1, 0], [0, 0]]}]}

    def test_round_trip_preserves_group_and_map(self):
        """Codecs preserve groups without baking their physical cells into map symbols."""
        self.assertEqual(encode_level(decode_level(self.level)), self.level)
        legacy = {key: value for key, value in self.level.items() if key != "props"}
        self.assertNotIn("props", encode_level(decode_level(legacy)))
        self.assertEqual(prop_solid_cells(legacy), set())

    def test_reflection_and_support_use_actual_fine_cells(self):
        """Support and blocking agree with the runtime's reflected six-pixel grid."""
        prop = self.level["props"][0]
        prop["solids"] = [[0, 0], [1, 0]]
        prop["mirrored"] = True
        cells = prop_solid_cells(self.level)
        self.assertEqual(cells, {(9, 10), (8, 10)})
        self.assertTrue(has_support(self.level["map"], cells, 48, 60, 60))
        self.assertFalse(has_support(self.level["map"], cells, 54, 66, 60))
        self.assertFalse(pixel_footprint_clear(self.level["map"], 54, 66, "@", cells))
        self.assertTrue(pixel_footprint_clear(self.level["map"], 54, 60, "@", cells))

    def test_entity_can_stand_on_prop_without_platform_tiles(self):
        """Ground entity validation accepts a prop floor and rejects a missing half."""
        terrain = ["." * 10] * 10
        terrain[8] = "##########"
        entities = ["." * 10] * 10
        entities[5] = ".....@...."
        entities[6] = "........O."
        hazards = ["." * 10] * 10
        self.level["props"][0]["solids"] = [[-2, 0], [-1, 0], [0, 0], [1, 0]]
        cells = prop_solid_cells(self.level)
        _validate_entities(terrain, hazards, entities, cells)
        with self.assertRaisesRegex(ValueError, "support|floor"):
            _validate_entities(terrain, hazards, entities, {(10, 10)})

    def test_malformed_groups_are_rejected(self):
        """Invalid IDs, definitions and coordinates cannot silently lose collision cells."""
        for field, value in [("type", "missing"), ("x", 5), ("x", True), ("mirrored", 1),
                             ("solids", [[0.5, 0]]), ("solids", [[-100, 0]]),
                             ("opacity", -1), ("opacity", 101), ("opacity", True),
                             ("opacity", 50.5), ("opacity", None), ("platform_layer", "front"),
                             ("jump_thrus", None), ("jump_thrus", [[0, 0.5]]),
                             ("jump_thrus", [[0, -100]]), ("jump_thrus", [[True, 0]])]:
            with self.subTest(field=field, value=value):
                level = copy.deepcopy(self.level)
                level["props"][0][field] = value
                with self.assertRaises(ValueError):
                    prop_solid_cells(level)
        self.level["props"].append(copy.deepcopy(self.level["props"][0]))
        with self.assertRaisesRegex(ValueError, "unique"):
            prop_solid_cells(self.level)
        self.assertEqual(len(prop_types()), 19)

    def test_one_way_support_is_separate_from_solid_obstacles(self):
        """One-way cells support standing, reflect and round-trip without blocking bodies."""
        prop = self.level["props"][0]
        prop.update(solids=[], jump_thrus=[[-2, 0], [-1, 0], [0, 0], [1, 0]], mirrored=True)
        solids, jumps = prop_collision_cells(self.level)
        self.assertEqual(solids, set())
        self.assertEqual(jumps, {(8, 10), (9, 10), (10, 10), (11, 10)})
        self.assertTrue(pixel_footprint_clear(self.level["map"], 60, 66, "@", solids))
        self.assertEqual(encode_level(decode_level(self.level)), self.level)
        terrain = ["." * 10] * 10
        terrain[8] = "##########"
        entities = ["." * 10] * 10
        entities[5], entities[6] = ".....@....", "........O."
        hazards = ["." * 10] * 10
        _validate_entities(terrain, hazards, entities, solids, jumps)
        with self.assertRaisesRegex(ValueError, "support|floor"):
            _validate_entities(terrain, hazards, entities, solids, {(10, 10)})

    def test_appearance_round_trip_does_not_change_collision_cells(self):
        """Invisible props and either draw layer keep their authored physical geometry."""
        original_cells = prop_solid_cells(self.level)
        for opacity in (0, 35, 100):
            for layer in ("above", "below"):
                with self.subTest(opacity=opacity, layer=layer):
                    self.level["props"][0].update(opacity=opacity, platform_layer=layer)
                    self.assertEqual(prop_solid_cells(self.level), original_cells)
                    self.assertEqual(encode_level(decode_level(self.level)), self.level)


if __name__ == "__main__":
    unittest.main()
