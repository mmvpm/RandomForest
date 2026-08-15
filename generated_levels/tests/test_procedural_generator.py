"""Regression tests for procedural semantic level generation."""

from __future__ import annotations

import json
import math
import random
import unittest
from collections import Counter
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from generated_levels.procedural import (
    GenerationProgress,
    TopologySettings,
    generate_level,
)
from generated_levels.procedural import config
from generated_levels.procedural.berry_distribution import (
    BerryCandidate,
    select_berry_candidates,
)
from generated_levels.procedural.affordance import platform_runs_are_supported
from generated_levels.procedural.cave import _terrain_from_air, generate_cave
from generated_levels.procedural.composition import (
    CompositionMetrics,
    composition_score,
)
from generated_levels.procedural.encounters import (
    EncounterZone,
    candidate_suitability,
)
from generated_levels.procedural.entities import (
    _choose_enemy_candidate,
    _sword_ray_clear,
    enemy_target,
    place_entities,
    scaled_entity_count,
)
from generated_levels.procedural.features import (
    _chain_candidates,
    _has_jump_affordance,
    _remove_shallow_spike_runs,
    _spike_run_rear_overlaps,
    place_jump_throughs,
    spike_has_deep_backing,
    spike_run_has_side_backing,
)
from generated_levels.procedural.frame import strip_outer_frame
from generated_levels.procedural.level_format import decode_level
from generated_levels.procedural.morphology import (
    analyze_morphology,
    collision_depth_is_qualified,
)
from generated_levels.procedural.placement import berry_has_safe_landing
from generated_levels.procedural.skeleton import (
    SkeletonAirResult,
    _lattice_adjacency,
    _maze_tree,
)
from generated_levels.procedural.skeleton_quality import (
    SkeletonMetrics,
    analyze_skeleton,
    select_loop_edges,
)
from generated_levels.procedural.star_times import (
    _greedy_route,
    calculate_star_times,
    ideal_route_seconds,
)
from generated_levels.procedural.topology import (
    analyze_topology,
    build_navigation_search,
    topology_is_qualified,
)
from generated_levels.procedural.validation import _validate_jump_throughs, validate_level


class ProceduralGeneratorTests(unittest.TestCase):
    """Verify deterministic output and hard generation constraints."""

    def test_same_seed_is_fully_deterministic(self) -> None:
        """The same dimensions and seed must produce identical JSON data."""
        first = generate_level(82, 47, 123456)
        second = generate_level(82, 47, 123456)
        self.assertEqual(first, second)

    def test_star_times_follow_greedy_route_formula(self) -> None:
        """Star thresholds must include flight, aiming, and configured factors."""
        self.assertEqual(config.THREE_STAR_TIME_FACTOR, 1.0)
        level = {
            "terrain": [
                "#######",
                "#.....#",
                "#.....#",
                "#######",
            ],
            "entities": [
                ".......",
                ".@.*.O.",
                "..*....",
                ".......",
            ],
        }
        route = _greedy_route(level)
        self.assertEqual(route[0][-1], (2, 2))
        ideal = ideal_route_seconds(level)
        thresholds = calculate_star_times(level)
        self.assertGreater(ideal, 1.0)
        self.assertEqual(
            thresholds["three_stars"],
            math.ceil(ideal * config.THREE_STAR_TIME_FACTOR),
        )
        self.assertEqual(
            thresholds["two_stars"],
            thresholds["three_stars"] * config.TWO_STAR_TIME_FACTOR,
        )

    def test_incompatible_close_spike_phases_are_rejected(self) -> None:
        """Aligned opposite runs must not overlap their black rear sections."""
        hazards = [list(".....") for _ in range(3)]
        hazards[1][1] = "L"
        self.assertTrue(
            _spike_run_rear_overlaps(hazards, ((3, 1),), "R")
        )
        hazards[1][1] = "<"
        self.assertFalse(
            _spike_run_rear_overlaps(hazards, ((3, 1),), ">")
        )

    def test_shallow_spike_cleanup_preserves_mass_and_opposing_spikes(self) -> None:
        """Only an air-backed spike run is removed from placed hazards."""
        terrain = [list(".......") for _ in range(3)]
        terrain[1][3] = "#"

        shallow_hazards = [list(".......") for _ in range(3)]
        shallow_hazards[1][4] = ">"
        _remove_shallow_spike_runs(
            terrain,
            shallow_hazards,
            [(((4, 1),), ">")],
        )
        self.assertEqual(shallow_hazards[1][4], ".")

        mass_hazards = [list(".......") for _ in range(3)]
        mass_hazards[1][4] = ">"
        terrain[1][2] = "X"
        _remove_shallow_spike_runs(
            terrain,
            mass_hazards,
            [(((4, 1),), ">")],
        )
        self.assertEqual(mass_hazards[1][4], ">")

        paired_hazards = [list(".......") for _ in range(3)]
        paired_hazards[1][2] = "<"
        paired_hazards[1][4] = ">"
        terrain[1][2] = "."
        _remove_shallow_spike_runs(
            terrain,
            paired_hazards,
            [(((2, 1),), "<"), (((4, 1),), ">")],
        )
        self.assertEqual("".join(paired_hazards[1]), "..<.>..")

    def test_spike_runs_require_two_cell_deep_black_sides(self) -> None:
        """Every run direction must extend its side mass behind the spike base."""
        cases = (
            (((2, 2), (3, 2), (4, 2)), "up", ((1, 2), (1, 3), (5, 2), (5, 3))),
            (((2, 4), (3, 4), (4, 4)), "down", ((1, 4), (1, 3), (5, 4), (5, 3))),
            (((2, 2), (2, 3), (2, 4)), "left", ((2, 1), (3, 1), (2, 5), (3, 5))),
            (((4, 2), (4, 3), (4, 4)), "right", ((4, 1), (3, 1), (4, 5), (3, 5))),
        )
        for cells, direction, side_cells in cases:
            with self.subTest(direction=direction):
                terrain = [list(".......") for _ in range(7)]
                for index, (x, y) in enumerate(side_cells):
                    terrain[y][x] = "#" if index % 2 == 0 else "X"
                self.assertTrue(
                    spike_run_has_side_backing(terrain, cells, direction)
                )
                missing_x, missing_y = side_cells[-1]
                terrain[missing_y][missing_x] = "."
                self.assertFalse(
                    spike_run_has_side_backing(terrain, cells, direction)
                )

    def test_jump_throughs_allow_two_cell_vertical_step(self) -> None:
        """Nearby platform runs may differ by two rows but never by only one."""
        self.assertEqual(config.JUMP_THRU_MIN_VERTICAL_STEP, 2)
        terrain = [list("........") for _ in range(8)]
        terrain[2][1] = "#"
        terrain[4][1] = "#"
        two_cell_step = [((2, 2), (3, 2)), ((2, 4), (3, 4))]
        with patch(
            "generated_levels.procedural.features._jump_through_candidates",
            return_value=two_cell_step,
        ):
            place_jump_throughs(terrain, 0, 7)
        self.assertEqual("".join(terrain[2][2:4]), "==")
        self.assertEqual("".join(terrain[4][2:4]), "==")
        _validate_jump_throughs(["".join(row) for row in terrain])

        terrain = [list("........") for _ in range(8)]
        terrain[2][1] = "#"
        terrain[3][1] = "#"
        one_cell_step = [((2, 2), (3, 2)), ((2, 3), (3, 3))]
        with patch(
            "generated_levels.procedural.features._jump_through_candidates",
            return_value=one_cell_step,
        ):
            place_jump_throughs(terrain, 0, 7)
        self.assertEqual(sum(cell == "=" for row in terrain for cell in row), 2)

    def test_jump_through_takeoff_rejects_three_cell_rise(self) -> None:
        """A side anchor must not mask a three-cell floor rise."""
        two_cell_terrain = [list("." * 24) for _ in range(16)]
        three_cell_terrain = [row[:] for row in two_cell_terrain]
        for x in range(3, 21):
            two_cell_terrain[11][x] = "#"
            three_cell_terrain[11][x] = "#"
        two_cell_platform = tuple((x, 9) for x in range(10, 13))
        three_cell_platform = tuple((x, 8) for x in range(10, 13))
        two_cell_terrain[9][13] = "#"
        three_cell_terrain[8][13] = "#"
        self.assertEqual(config.JUMP_THRU_MAX_UPWARD_STEP, 2)
        self.assertTrue(_has_jump_affordance(two_cell_terrain, two_cell_platform))
        self.assertFalse(
            _has_jump_affordance(three_cell_terrain, three_cell_platform)
        )

    def test_platform_chain_candidates_use_exact_two_cell_steps(self) -> None:
        """Consecutive chain runs must use the configured comfortable step."""
        terrain = [list("." * 24) for _ in range(16)]
        source = ((10, 8), (11, 8))
        with (
            patch(
                "generated_levels.procedural.features._has_jump_affordance",
                return_value=True,
            ),
            patch(
                "generated_levels.procedural.features._jump_trajectory_clear",
                return_value=True,
            ),
        ):
            candidates = _chain_candidates(terrain, source)
        self.assertEqual(
            {run[0][1] for run in candidates},
            {source[0][1] - 2, source[0][1] + 2},
        )

    def test_enemy_suitability_strongly_prefers_patrol_width(self) -> None:
        """An ordinary full-width floor must beat an equivalent narrow floor."""
        zone = EncounterZone((6, 8), 0.5, 0.6, 0.0, 0.5)
        narrow = [list("." * 13) for _ in range(10)]
        wide = [row[:] for row in narrow]
        narrow[8][5:8] = "###"
        wide[8][4:9] = "#####"
        narrow_cost = candidate_suitability(narrow, "S", (6, 8), 0.5, zone)
        wide_cost = candidate_suitability(wide, "S", (6, 8), 0.5, zone)
        self.assertGreater(narrow_cost - wide_cost, 0.8)

    def test_context_can_still_make_a_skeleton_perch_win(self) -> None:
        """A strong encounter fit may still justify a short skeleton perch."""
        terrain = [list("." * 24) for _ in range(12)]
        terrain[8][3:6] = "###"
        terrain[8][14:20] = "######"
        zone = EncounterZone((4, 8), 0.2, 0.5, 0.0, 0.5)
        perch_cost = candidate_suitability(terrain, "K", (4, 8), 0.2, zone)
        distant_cost = candidate_suitability(terrain, "K", (16, 8), 0.5, zone)
        self.assertLess(perch_cost, distant_cost)

    def test_enemy_choice_compares_geometry_across_types(self) -> None:
        """A much better alternate type may beat the randomly preferred type."""
        terrain = [list("." * 12) for _ in range(10)]
        route = [((2, 8), 0.0), ((9, 8), 1.0)]
        zone = EncounterZone((6, 8), 0.5, 0.5, 0.0, 0.5)
        candidates = {"S": [(4, 8)], "K": [], "B": [(8, 8)]}
        with patch(
            "generated_levels.procedural.entities.candidate_suitability",
            side_effect=lambda _terrain, symbol, *_args: 0.0 if symbol == "S" else 1.0,
        ):
            choice = _choose_enemy_candidate(
                terrain,
                candidates,
                [],
                route,
                zone,
                "B",
                random.Random(7),
            )
        self.assertEqual(choice, ("S", (4, 8)))

    def test_entity_placement_does_not_repair_terrain(self) -> None:
        """Entity layout must leave the accepted cave geometry unchanged."""
        terrain = [list("." * 12) for _ in range(10)]
        terrain[8][1:11] = "##########"
        hazards = [list("." * 12) for _ in range(10)]
        selected_route = ((3, 8), (4, 7), (6, 7), (8, 6))
        before = [row[:] for row in terrain]
        with (
            patch(
                "generated_levels.procedural.entities._choose_start_and_door_floor",
                return_value=((3, 8), (8, 8), selected_route),
            ),
            patch(
                "generated_levels.procedural.entities.build_encounter_zones",
                return_value=(),
            ),
            patch(
                "generated_levels.procedural.entities.encounter_enemy_target",
                return_value=0,
            ),
            patch(
                "generated_levels.procedural.entities.scaled_entity_count",
                return_value=0,
            ),
            patch(
                "generated_levels.procedural.entities._berry_candidates",
                return_value=[],
            ),
            patch(
                "generated_levels.procedural.entities.select_berry_candidates",
                return_value=[],
            ),
        ):
            place_entities(terrain, hazards, selected_route, 7)
        self.assertEqual(terrain, before)

    def test_different_seeds_change_geometry(self) -> None:
        """Different seeds must not merely restyle the same semantic map."""
        first = generate_level(82, 47, 111)
        second = generate_level(82, 47, 222)
        self.assertNotEqual(first["map"], second["map"])

    def test_showcase_size_has_authored_content_balance(self) -> None:
        """A standard map must contain terrain features, rewards, and enemies."""
        encoded_level = generate_level(82, 47, 361769532)
        validate_level(encoded_level)
        level = decode_level(encoded_level)
        terrain = Counter("".join(level["terrain"]))
        hazards = Counter("".join(level["hazards"]))
        entities = Counter("".join(level["entities"]))
        area = int(level["width"]) * int(level["height"])
        self.assertGreaterEqual(terrain["."] / area, config.MIN_AIR_RATIO - 0.03)
        self.assertLessEqual(terrain["."] / area, config.MAX_AIR_RATIO)
        self.assertGreater(terrain["="], 0)
        self.assertGreater(sum(hazards[symbol] for symbol in "^v<>UDLR"), 0)
        inner_area = (
            int(level["width"]) - config.OUTER_X_PADDING * 2
        ) * (int(level["height"]) - config.OUTER_X_PADDING * 2)
        expected_berries = scaled_entity_count(
            config.REFERENCE_BERRIES,
            inner_area,
            config.BERRY_GROWTH_EXPONENT,
            config.MIN_BERRIES,
        )
        self.assertGreaterEqual(
            entities["*"],
            max(
                config.MIN_BERRIES,
                expected_berries - config.BERRY_COUNT_VARIATION,
            ),
        )
        self.assertLessEqual(
            entities["*"],
            expected_berries + config.BERRY_COUNT_VARIATION,
        )
        expected_enemies = enemy_target(inner_area)
        actual_enemies = sum(entities[symbol] for symbol in "SsKkBb")
        self.assertGreaterEqual(actual_enemies, expected_enemies)
        self.assertLessEqual(
            actual_enemies,
            expected_enemies + round(expected_enemies * config.ENCOUNTER_MAX_BONUS_RATIO),
        )
        hazard_target = round(terrain["."] * config.HAZARD_AIR_RATIO)
        hazard_count = sum(hazards[symbol] for symbol in "^v<>UDLR")
        self.assertGreaterEqual(hazard_count, hazard_target * config.MIN_HAZARD_TARGET_RATIO)
        singleton_positions = [
            (x, y)
            for y, row in enumerate(level["entities"])
            for x, symbol in enumerate(row)
            if symbol in "@Oo"
        ]
        self.assertGreater(
            math.dist(singleton_positions[0], singleton_positions[1]),
            (int(level["width"]) - config.OUTER_X_PADDING * 2) * 0.45,
        )
        content_positions = [
            (x, y)
            for y, row in enumerate(level["entities"])
            for x, symbol in enumerate(row)
            if symbol in "*SsKkBb"
        ]
        horizontal_span = max(x for x, _ in content_positions) - min(
            x for x, _ in content_positions
        )
        vertical_span = max(y for _, y in content_positions) - min(y for _, y in content_positions)
        self.assertTrue(
            horizontal_span >= int(level["width"]) * 0.5
            or vertical_span >= int(level["height"]) * 0.5
        )
        inner_terrain = strip_outer_frame(
            level["terrain"], config.OUTER_X_PADDING
        )
        topology = analyze_topology(inner_terrain)
        self.assertTrue(topology_is_qualified(topology, config.DEFAULT_TOPOLOGY))
        self.assertGreaterEqual(
            abs(singleton_positions[0][0] - singleton_positions[1][0]),
            (int(level["width"]) - config.OUTER_X_PADDING * 2) * 0.45,
        )
        player = next(
            (x, y)
            for y, row in enumerate(level["entities"])
            for x, symbol in enumerate(row)
            if symbol == "@"
        )
        door = next(
            (x, y)
            for y, row in enumerate(level["entities"])
            for x, symbol in enumerate(row)
            if symbol in "Oo"
        )
        endpoint_search = build_navigation_search(level["terrain"], player)
        endpoint_detour = endpoint_search.distances[door] / math.dist(player, door)
        self.assertGreaterEqual(
            endpoint_detour, config.DEFAULT_TOPOLOGY.min_endpoint_detour_ratio
        )
        self.assertFalse(endpoint_search.line_clear_to(door))

    def test_content_counts_scale_from_inner_level_area(self) -> None:
        """Reference and very large maps must use predictable content targets."""
        reference_area = config.REFERENCE_LEVEL_AREA
        self.assertEqual(enemy_target(reference_area), 11)
        self.assertEqual(
            scaled_entity_count(
                config.REFERENCE_BERRIES,
                reference_area,
                config.BERRY_GROWTH_EXPONENT,
                config.MIN_BERRIES,
            ),
            12,
        )
        large_area = (500 - config.OUTER_X_PADDING * 2) * (
            300 - config.OUTER_X_PADDING * 2
        )
        self.assertEqual(enemy_target(large_area), 88)
        self.assertEqual(
            scaled_entity_count(
                config.REFERENCE_BERRIES,
                large_area,
                config.BERRY_GROWTH_EXPONENT,
                config.MIN_BERRIES,
            ),
            140,
        )

    def test_generation_keeps_searching_until_three_candidates(self) -> None:
        """Candidate rejection must not stop at the former attempt limit."""
        cave = SimpleNamespace(
            terrain=[["."]],
            air={(0, 0)},
            route=(),
            topology=object(),
            morphology=object(),
            skeleton=SkeletonMetrics(1.0, 0.0, 0, 0.0),
        )
        progress: list[GenerationProgress] = []
        entity_layers = iter(([["1"]], [["2"]], [["3"]]))
        with (
            patch(
                "generated_levels.procedural.generator.generate_cave",
                return_value=cave,
            ) as generate_cave_mock,
            patch(
                "generated_levels.procedural.generator.topology_is_qualified",
                side_effect=[False] * 49 + [True] * 3,
            ),
            patch(
                "generated_levels.procedural.generator.morphology_is_qualified",
                return_value=True,
            ),
            patch("generated_levels.procedural.generator.place_jump_throughs"),
            patch(
                "generated_levels.procedural.generator.place_hazards",
                return_value=[["^"]],
            ),
            patch(
                "generated_levels.procedural.generator.place_entities",
                side_effect=lambda *args: next(entity_layers),
            ),
            patch(
                "generated_levels.procedural.generator.add_outer_frame",
                side_effect=lambda level, padding: level,
            ),
            patch("generated_levels.procedural.generator.validate_level"),
            patch(
                "generated_levels.procedural.generator._full_level_score",
                side_effect=(1.0, 3.0, 2.0),
            ),
            patch(
                "generated_levels.procedural.generator.calculate_star_times",
                return_value={"three_stars": 1, "two_stars": 2},
            ),
            patch(
                "generated_levels.procedural.generator.encode_level",
                side_effect=lambda selected: selected,
            ),
            patch.object(config, "CONTENT_LAYOUT_VARIANTS", 1),
        ):
            level = generate_level(46, 29, 123, progress=progress.append)
        self.assertEqual(generate_cave_mock.call_count, 52)
        self.assertEqual(level["entities"], ["2"])
        accepted = [state for state in progress if state.stage == "accepted"]
        self.assertEqual([state.valid_candidates for state in accepted], [1, 2, 3])
        self.assertEqual(accepted[-1].topology_rejected, 49)

    def test_generation_compares_content_layouts_on_one_cave(self) -> None:
        """One accepted geometry must receive several independently scored layouts."""
        cave = SimpleNamespace(topology=object(), morphology=object())
        layouts = (
            (1.0, {"choice": "first"}),
            (4.0, {"choice": "best"}),
            (2.0, {"choice": "last"}),
        )
        with (
            patch(
                "generated_levels.procedural.generator.generate_cave",
                return_value=cave,
            ) as generate_cave_mock,
            patch(
                "generated_levels.procedural.generator.topology_is_qualified",
                return_value=True,
            ),
            patch(
                "generated_levels.procedural.generator.morphology_is_qualified",
                return_value=True,
            ),
            patch(
                "generated_levels.procedural.generator._content_layout",
                side_effect=layouts,
            ) as content_layout_mock,
            patch(
                "generated_levels.procedural.generator.encode_level",
                side_effect=lambda selected: selected,
            ),
        ):
            level = generate_level(
                46,
                29,
                123,
                TopologySettings(valid_candidate_target=1),
            )
        self.assertEqual(level["choice"], "best")
        self.assertEqual(generate_cave_mock.call_count, 1)
        self.assertEqual(content_layout_mock.call_count, config.CONTENT_LAYOUT_VARIANTS)

    def test_collision_shell_thickness_does_not_cascade(self) -> None:
        """The decorative second shell must read only the frozen first shell."""
        air = [[False] * 9 for _ in range(9)]
        air[4][4] = True
        with patch(
            "generated_levels.procedural.cave.warped_fbm",
            return_value=1.0,
        ):
            terrain = _terrain_from_air(air, 7)
        self.assertEqual(terrain[4][2], "#")
        self.assertEqual(terrain[4][1], "X")
        self.assertTrue(collision_depth_is_qualified(terrain))
        terrain[4][1] = "#"
        self.assertFalse(collision_depth_is_qualified(terrain))

    def test_floating_platform_must_link_to_rock_affordance(self) -> None:
        """A floating run is valid only as part of a reachable construction."""
        terrain = [list("....................") for _ in range(20)]
        for x in range(2, 7):
            terrain[15][x] = "#"
        terrain[15][7:9] = "=="
        terrain[12][9:11] = "=="
        self.assertTrue(platform_runs_are_supported(terrain))
        terrain[12][9:11] = ".."
        terrain[5][15:17] = "=="
        self.assertFalse(platform_runs_are_supported(terrain))

    def test_composition_score_rewards_rhythm_and_useful_features(self) -> None:
        """Composition scoring must prefer directed scenes over empty pacing."""
        sparse = CompositionMetrics(5, 4, 0, 1, 1, 2, 1, 4, 4.0)
        directed = CompositionMetrics(9, 1, 0, 3, 4, 5, 0, 2, 2.0)
        self.assertGreater(composition_score(directed), composition_score(sparse))

    def test_lattice_keeps_horizontal_connections_on_outer_rows(self) -> None:
        """Top and bottom nodes must not be forced into vertical teeth."""
        coordinates = [
            (column, row)
            for row in range(3)
            for column in range(4)
        ]
        lookup = {
            coordinate: index for index, coordinate in enumerate(coordinates)
        }
        adjacency = _lattice_adjacency(coordinates, lookup)
        self.assertIn(lookup[(1, 0)], adjacency[lookup[(0, 0)]])
        self.assertIn(lookup[(2, 2)], adjacency[lookup[(1, 2)]])

    def test_maze_tree_is_connected_and_moderately_horizontal(self) -> None:
        """Kruskal selection must build one tree without long vertical combs."""
        coordinates = [
            (column, row)
            for row in range(5)
            for column in range(8)
        ]
        nodes = [
            (float(column * 10), float(row * 9))
            for column, row in coordinates
        ]
        lookup = {
            coordinate: index for index, coordinate in enumerate(coordinates)
        }
        adjacency = _lattice_adjacency(coordinates, lookup)
        first = _maze_tree(nodes, adjacency, random.Random(11))
        second = _maze_tree(nodes, adjacency, random.Random(11))
        metrics = analyze_skeleton(nodes, first)
        self.assertEqual(first, second)
        self.assertEqual(len(first), len(nodes) - 1)
        self.assertGreaterEqual(
            metrics.horizontal_ratio,
            config.SKELETON_MIN_HORIZONTAL_RATIO,
        )
        self.assertLessEqual(
            metrics.max_vertical_chain,
            config.SKELETON_MAX_VERTICAL_CHAIN,
        )

    def test_loop_selection_closes_a_meaningful_tree_path(self) -> None:
        """A non-tree edge must close the available six-edge route."""
        nodes = [(float(index), 0.0) for index in range(7)]
        tree = [(index, index + 1) for index in range(6)]
        adjacency = [[] for _ in nodes]
        for first, second in tree + [(0, 6)]:
            adjacency[first].append(second)
            adjacency[second].append(first)
        loops = select_loop_edges(nodes, adjacency, tree, 1)
        self.assertEqual(loops, [(0, 6)])
        metrics = analyze_skeleton(nodes, tree, loops)
        self.assertEqual(metrics.loop_count, 1)
        self.assertEqual(metrics.cycle_coverage_ratio, 1.0)

    def test_invalid_ring_variant_falls_back_to_base_cave(self) -> None:
        """A loop that fails old topology gates must not replace its base."""
        metrics = SkeletonMetrics(0.8, 0.2, 0, 0.0)
        variants = SkeletonAirResult(
            base_air=[[True]],
            base_metrics=metrics,
            nodes=[(0.0, 0.0)],
            tree_edges=[],
            loop_edges=[(0, 0)],
        )
        looped_metrics = SkeletonMetrics(0.8, 0.2, 1, 0.5)
        base = SimpleNamespace(
            topology=object(),
            morphology=object(),
            skeleton=metrics,
        )
        looped = SimpleNamespace(
            topology=object(),
            morphology=object(),
            skeleton=looped_metrics,
        )
        with (
            patch(
                "generated_levels.procedural.cave.generate_skeleton_air",
                return_value=variants,
            ),
            patch(
                "generated_levels.procedural.cave._build_cave_result",
                side_effect=(base, looped),
            ),
            patch(
                "generated_levels.procedural.cave.rasterize_looped_skeleton",
                return_value=([[False]], looped_metrics),
            ),
            patch(
                "generated_levels.procedural.cave.topology_is_qualified",
                side_effect=(True, False),
            ),
            patch(
                "generated_levels.procedural.cave.morphology_is_qualified",
                return_value=True,
            ),
        ):
            selected = generate_cave(10, 10, 1)
        self.assertIs(selected, base)

    def test_berry_distribution_spreads_and_uses_variable_count(self) -> None:
        """Greedy placement must skip close access points and cover long gaps."""
        candidates = [
            BerryCandidate(
                point=(position, 0),
                access_point=(position, 0),
                quality=0.0,
                branch_depth=float(position),
                guarded_enemies=frozenset({0}) if position == 20 else frozenset(),
            )
            for position in (0, 5, 20, 40, 60, 80)
        ]

        def line_distances(start: tuple[int, int]) -> dict[tuple[int, int], float]:
            """Return exact distances along the synthetic straight branch."""
            return {
                candidate.access_point: abs(candidate.access_point[0] - start[0])
                for candidate in candidates
            }

        selected = select_berry_candidates(
            candidates,
            base_target=4,
            distance_maps=line_distances,
            rng=random.Random(7),
        )
        self.assertGreaterEqual(len(selected), 4)
        self.assertLessEqual(len(selected), 6)
        self.assertIn((20, 0), [candidate.point for candidate in selected])
        for index, first in enumerate(selected):
            for second in selected[index + 1 :]:
                self.assertGreaterEqual(
                    abs(first.access_point[0] - second.access_point[0]),
                    config.BERRY_MIN_PATH_DISTANCE,
                )
        compact = [
            BerryCandidate(
                point=(position, 0),
                access_point=(position, 0),
                quality=0.0,
                branch_depth=float(position),
                guarded_enemies=frozenset(),
            )
            for position in (0, 10, 20, 30)
        ]
        compact_selected = select_berry_candidates(
            compact,
            base_target=6,
            distance_maps=lambda start: {
                candidate.access_point: abs(candidate.access_point[0] - start[0])
                for candidate in compact
            },
            rng=random.Random(7),
        )
        self.assertEqual(len(compact_selected), 4)

    def test_seed_matrix_preserves_selected_cave_composition(self) -> None:
        """Known standard seeds must keep natural outside mass and dense interiors."""
        for seed in (111, 222, 123456, 26238431, 361769532, 98765):
            with self.subTest(seed=seed):
                level = decode_level(generate_level(82, 47, seed))
                inner_terrain = strip_outer_frame(
                    level["terrain"], config.OUTER_X_PADDING
                )
                metrics = analyze_morphology(inner_terrain)
                self.assertGreaterEqual(
                    metrics.external_rock_ratio,
                    config.DEFAULT_TOPOLOGY.min_external_rock_ratio,
                )
                self.assertLessEqual(
                    metrics.external_rock_ratio,
                    config.DEFAULT_TOPOLOGY.max_external_rock_ratio,
                )
                self.assertGreaterEqual(metrics.playable_bbox_ratio, 0.82)
                self.assertLessEqual(
                    metrics.maximum_flat_run, config.MAX_FLAT_SURFACE_RUN
                )
                self.assertLessEqual(
                    metrics.central_open_span_ratio,
                    config.MAX_CENTRAL_OPEN_SPAN_RATIO,
                )

    def test_showcase_satisfies_single_player_topology(self) -> None:
        """The hand-authored reference must satisfy the default topology gates."""
        showcase_path = Path(__file__).parents[1] / "showcase.json"
        showcase = decode_level(
            json.loads(showcase_path.read_text(encoding="utf-8"))
        )
        topology = analyze_topology(showcase["terrain"])
        self.assertTrue(topology_is_qualified(topology, config.DEFAULT_TOPOLOGY))
        player = next(
            (x, y)
            for y, row in enumerate(showcase["entities"])
            for x, symbol in enumerate(row)
            if symbol == "@"
        )
        door = next(
            (x, y)
            for y, row in enumerate(showcase["entities"])
            for x, symbol in enumerate(row)
            if symbol in "Oo"
        )
        endpoint_search = build_navigation_search(showcase["terrain"], player)
        self.assertGreaterEqual(
            endpoint_search.distances[door] / math.dist(player, door),
            config.DEFAULT_TOPOLOGY.min_endpoint_detour_ratio,
        )
        self.assertFalse(endpoint_search.line_clear_to(door))

    def test_open_topology_remains_available_through_parameters(self) -> None:
        """Technical settings must retain the former arena-like generator range."""
        open_topology = TopologySettings(
            loop_density=1.0,
            corridor_width_scale=1.0,
            min_route_detour_ratio=1.0,
            min_endpoint_detour_ratio=1.0,
            require_endpoint_occlusion=False,
            min_horizontal_surface_ratio=0.5,
            max_long_route_sightline_ratio=0.4,
            min_external_rock_ratio=0.10,
            max_external_rock_ratio=0.45,
            valid_candidate_target=1,
        )
        level = generate_level(82, 47, 24680, open_topology)
        validate_level(level)
        self.assertIn("map", level)
        self.assertNotIn("terrain", level)

    def test_large_map_preserves_the_format_contract(self) -> None:
        """A two-times-wide and two-times-high map must remain valid."""
        encoded_level = generate_level(164, 94, 987654321)
        validate_level(encoded_level)
        level = decode_level(encoded_level)
        self.assertEqual(len(level["terrain"]), 94)
        self.assertTrue(all(len(row) == 164 for row in level["terrain"]))
        inner_terrain = strip_outer_frame(
            level["terrain"], config.OUTER_X_PADDING
        )
        morphology = analyze_morphology(inner_terrain)
        self.assertGreaterEqual(
            morphology.external_rock_ratio,
            config.DEFAULT_TOPOLOGY.min_external_rock_ratio,
        )
        self.assertLessEqual(
            morphology.external_rock_ratio,
            config.DEFAULT_TOPOLOGY.max_external_rock_ratio,
        )

    def test_output_has_two_cell_outer_frame(self) -> None:
        """Requested dimensions must include an algorithm-independent X frame."""
        level = decode_level(generate_level(82, 47, 26238431))
        padding = config.OUTER_X_PADDING
        for layer_name, border_symbol in (
            ("terrain", "X"),
            ("hazards", "."),
            ("entities", "."),
        ):
            rows = level[layer_name]
            self.assertEqual(len(rows), 47)
            self.assertTrue(all(len(row) == 82 for row in rows))
            self.assertTrue(
                all(
                    cell == border_symbol
                    for y, row in enumerate(rows)
                    for x, cell in enumerate(row)
                    if x < padding
                    or x >= 82 - padding
                    or y < padding
                    or y >= 47 - padding
                )
            )

    def test_every_spike_has_lateral_and_deep_support(self) -> None:
        """Every spike must have lateral support and two-cell rear backing."""
        level = decode_level(generate_level(82, 47, 26238431))
        terrain = level["terrain"]
        hazards = level["hazards"]
        for y, row in enumerate(hazards):
            for x, symbol in enumerate(row):
                if symbol == ".":
                    continue
                neighbors = (
                    ((x - 1, y), (x + 1, y))
                    if symbol in "^vUD"
                    else ((x, y - 1), (x, y + 1))
                )
                self.assertTrue(
                    all(
                        terrain[ny][nx] in "#X" or hazards[ny][nx] != "."
                        for nx, ny in neighbors
                    ),
                    f"Spike side is unsupported at {(x, y)}",
                )
                self.assertTrue(
                    spike_has_deep_backing(terrain, hazards, x, y, symbol),
                    f"Spike backing is only one cell deep at {(x, y)}",
                )

    def test_berry_between_spikes_has_no_safe_collection_landing(self) -> None:
        """A reward squeezed between spike columns must be rejected."""
        terrain = [list(".........") for _ in range(9)]
        safe_hazards = [list(".........") for _ in range(9)]
        trapped_hazards = [row[:] for row in safe_hazards]
        for y in range(9):
            trapped_hazards[y][3] = ">"
            trapped_hazards[y][5] = "<"
        self.assertTrue(berry_has_safe_landing(terrain, safe_hazards, (4, 4)))
        self.assertFalse(berry_has_safe_landing(terrain, trapped_hazards, (4, 4)))

    def test_every_berry_is_globally_collectible(self) -> None:
        """Rewards need walking access or a clear sword throw from reachable air."""
        level = decode_level(generate_level(82, 47, 111))
        terrain = [list(row) for row in level["terrain"]]
        player = next(
            (x, y)
            for y, row in enumerate(level["entities"])
            for x, symbol in enumerate(row)
            if symbol == "@"
        )
        berries = [
            (x, y)
            for y, row in enumerate(level["entities"])
            for x, symbol in enumerate(row)
            if symbol == "*"
        ]
        navigation = build_navigation_search(terrain, player)
        for berry in berries:
            walk_accessible = any(
                (x, y) in navigation.distances
                for y in range(berry[1], berry[1] + 3)
                for x in range(berry[0] - 1, berry[0] + 2)
            )
            sword_accessible = any(
                _sword_ray_clear(terrain, point, berry)
                for point in navigation.distances
            )
            self.assertTrue(
                walk_accessible or sword_accessible,
                f"Berry is globally unreachable at {berry}",
            )

    def test_too_small_dimensions_are_rejected(self) -> None:
        """Rooms smaller than the camera-safe dimensions must fail clearly."""
        with self.assertRaises(ValueError):
            generate_level(config.MIN_WIDTH - 1, config.MIN_HEIGHT, 1)


if __name__ == "__main__":
    unittest.main()
