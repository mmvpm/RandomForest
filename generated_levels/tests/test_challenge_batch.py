"""Tests for append-only challenge catalog orchestration."""

from __future__ import annotations

import json
import random
import tempfile
import unittest
from pathlib import Path

from generated_levels.challenge_batch import (
    choose_dimensions,
    level_file_name,
    next_level_number,
    refresh_runtime_catalog,
    write_new_level,
)


class ChallengeBatchTests(unittest.TestCase):
    """Verify production catalog naming and project registration."""

    def test_new_levels_continue_after_the_highest_existing_number(self) -> None:
        """Existing levels must never be selected as output targets."""
        with tempfile.TemporaryDirectory() as directory:
            output_directory = Path(directory)
            write_new_level({"width": 70}, output_directory / "01.json")
            write_new_level({"width": 80}, output_directory / "09.json")
            self.assertEqual(next_level_number(output_directory), 10)
            self.assertEqual(level_file_name(10), "10.json")

    def test_existing_level_cannot_be_overwritten(self) -> None:
        """The writer must enforce append-only output at filesystem level."""
        with tempfile.TemporaryDirectory() as directory:
            output_path = Path(directory) / "01.json"
            write_new_level({"width": 70}, output_path)
            with self.assertRaises(FileExistsError):
                write_new_level({"width": 80}, output_path)
            self.assertEqual(
                json.loads(output_path.read_text(encoding="utf-8"))["width"],
                70,
            )

    def test_dimensions_stay_inside_the_configured_ranges(self) -> None:
        """Every random size must honor both inclusive bounds."""
        random_source = random.Random(123)
        for _ in range(100):
            width, height = choose_dimensions(
                random_source,
                (70, 110),
                (40, 60),
            )
            self.assertIn(width, range(70, 111))
            self.assertIn(height, range(40, 61))

    def test_catalog_and_project_registration_are_ordered_and_idempotent(self) -> None:
        """Refreshing twice must produce the same catalog and project text."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output_directory = root / "datafiles" / "challenge_levels"
            output_directory.mkdir(parents=True)
            write_new_level({"width": 80}, output_directory / "10.json")
            write_new_level({"width": 70}, output_directory / "02.json")
            project_path = root / "game.yyp"
            project_path.write_text(
                '{\n'
                '  "IncludedFiles":[\n'
                '    {"filePath":"datafiles","name":"font.ttf",},\n'
                "  ],\n"
                '  "resources":[],\n'
                "}\n",
                encoding="utf-8",
            )

            refresh_runtime_catalog(project_path, output_directory)
            first_project = project_path.read_text(encoding="utf-8")
            refresh_runtime_catalog(project_path, output_directory)

            catalog = json.loads(
                (output_directory / "catalog.json").read_text(encoding="utf-8")
            )
            self.assertEqual(
                catalog["levels"],
                [
                    "challenge_levels/02.json",
                    "challenge_levels/10.json",
                ],
            )
            self.assertEqual(project_path.read_text(encoding="utf-8"), first_project)
            self.assertIn('"name":"font.ttf"', first_project)
            self.assertEqual(first_project.count('"name":"catalog.json"'), 1)
            self.assertEqual(first_project.count('"name":"02.json"'), 1)
            self.assertEqual(first_project.count('"name":"10.json"'), 1)


if __name__ == "__main__":
    unittest.main()
