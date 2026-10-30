"""Check campaign boundaries and the physical niches of the new families."""

import random
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from generated_levels import challenge_batch, procedural
from generated_levels.procedural import config
from generated_levels.procedural.enemy_placement import bat_candidates, ground_encounter_fits
from generated_levels.procedural.entities import _weighted_enemy


class EnemyRosterTests(unittest.TestCase):
    """Prevent theme fallback artwork and impossible encounter placements."""

    def test_absolute_game_number_boundaries(self):
        """Challenge numbering must not shift evening/night by ten levels."""
        for number, theme in ((1, "day"), (20, "day"), (21, "evening"),
                              (30, "evening"), (31, "night"), (40, "night"), (41, "morning")):
            self.assertEqual(config.level_theme(number), theme)
        with self.assertRaises(ValueError):
            config.level_theme(0)

    def test_roster_uses_only_available_skins(self):
        """The config is the authoritative map of skins, including universal old enemies."""
        expected = {11: set("SKBG"), 22: set("SKBJG"), 32: set("SKBJGCTW"), 41: set("SKBJG")}
        for number, symbols in expected.items():
            weights = config.enemy_weights(number)
            self.assertEqual({symbol for symbol, _ in weights}, symbols)
            self.assertAlmostEqual(sum(weight for _, weight in weights), 1)
            for symbol, weight in weights:
                self.assertGreater(weight, 0)
                self.assertIn(config.level_theme(number), config.ENEMY_SKINS[symbol])
            sampled = {_weighted_enemy(random.Random(seed), number) for seed in range(500)}
            self.assertEqual(sampled, symbols)

    def test_bats_need_ceiling_and_a_real_dive_chamber(self):
        """A floor-only or narrow tunnel must never become a hanging bat encounter."""
        terrain = [list("." * 24) for _ in range(16)]
        hazards = [list("." * 24) for _ in range(16)]
        terrain[2] = list("#" * 24)
        terrain[13] = list("#" * 24)
        self.assertIn((12, 5), bat_candidates(terrain, hazards))
        no_ceiling = [row[:] for row in terrain]
        no_ceiling[2] = list("." * 24)
        self.assertEqual(bat_candidates(no_ceiling, hazards), [])
        terrain[7] = list("#" * 24)
        self.assertNotIn((12, 5), bat_candidates(terrain, hazards))

    def test_big_attackers_and_hoppers_need_clearance(self):
        """Do not squeeze a reaper into a perch or a hopper under a low ceiling."""
        terrain = [list("." * 30) for _ in range(16)]
        terrain[12] = list("#" * 30)
        for symbol in "JCGWF":
            self.assertTrue(ground_encounter_fits(terrain, 14, 12, symbol))
        terrain[7][14] = "#"
        self.assertFalse(ground_encounter_fits(terrain, 14, 12, "J"))
        terrain[10][11] = "#"
        self.assertFalse(ground_encounter_fits(terrain, 14, 12, "W"))

    def test_maw_has_clearance_for_both_facing_directions(self):
        """A right-facing footprint alone must not accept a left-facing jaw inside rock."""
        terrain = [list("." * 30) for _ in range(16)]
        terrain[12] = list("#" * 30)
        self.assertTrue(ground_encounter_fits(terrain, 14, 12, "F"))
        terrain[10][10] = "#"
        self.assertFalse(ground_encounter_fits(terrain, 14, 12, "F"))

    def test_batch_passes_the_game_number_instead_of_the_json_number(self):
        """The first replaceable JSON is 12, but its roster must be evening level 22."""
        path = Path(__file__).resolve().parents[1] / "generate_procedural_level.py"
        spec = importlib.util.spec_from_file_location("roster_batch_test", path)
        module = importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules, {"challenge_batch": challenge_batch, "procedural": procedural}):
            spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(module, "OUTPUT_DIRECTORY", Path(folder)), \
                patch.object(module, "BATCH_LEVEL_COUNT", 1), \
                patch.object(module, "next_level_number", return_value=12), \
                patch.object(module, "generate_level", return_value={"map": []}) as generate, \
                patch("builtins.print"):
            module.generate_batch()
            self.assertEqual(generate.call_args.kwargs["game_level"], 22)
            self.assertTrue((Path(folder) / "12.json").exists())


if __name__ == "__main__":
    unittest.main()
