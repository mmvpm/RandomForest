#!/usr/bin/env python3
"""Append a configured batch of procedural levels to the game catalog."""

from __future__ import annotations

import random
import sys
import time
from pathlib import Path

from challenge_batch import (
    choose_dimensions,
    level_file_name,
    next_level_number,
    refresh_runtime_catalog,
    write_new_level,
)
from procedural import GenerationProgress, TopologySettings, generate_level


# Edit these values before running this script
BATCH_LEVEL_COUNT = 10
LEVEL_WIDTH_RANGE = (70, 110)
LEVEL_HEIGHT_RANGE = (40, 60)
LEVEL_TOPOLOGY = TopologySettings()
PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIRECTORY = PROJECT_ROOT / "RandomForest" / "datafiles" / "challenge_levels"
GAME_PROJECT_PATH = PROJECT_ROOT / "RandomForest" / "RandomForest.yyp"


def format_progress(progress: GenerationProgress, elapsed: float) -> str:
    """Format one compact status line for a long generation run."""
    message = (
        f"attempt {progress.attempt} | {progress.stage} | "
        f"valid {progress.valid_candidates}/{progress.target_candidates} | "
        f"rejected T:{progress.topology_rejected} "
        f"M:{progress.morphology_rejected} C:{progress.content_rejected} | "
        f"{elapsed:.1f}s"
    )
    if progress.last_error:
        message += f" | {progress.last_error}"
    return message


def generate_batch() -> int:
    """Generate new numbered files and preserve all completed earlier output."""
    random_source = random.SystemRandom()
    first_level_number = next_level_number(OUTPUT_DIRECTORY)

    for batch_index in range(BATCH_LEVEL_COUNT):
        level_number = first_level_number + batch_index
        width, height = choose_dimensions(
            random_source,
            LEVEL_WIDTH_RANGE,
            LEVEL_HEIGHT_RANGE,
        )
        seed = random_source.randint(0, 10**9)
        started = time.monotonic()

        def show_progress(progress: GenerationProgress) -> None:
            """Replace the current terminal line with current level progress."""
            message = format_progress(progress, time.monotonic() - started)
            prefix = (
                f"level {level_number} ({batch_index + 1}/{BATCH_LEVEL_COUNT}) "
                f"| {width}x{height}"
            )
            print(
                f"\r\033[2K{prefix} | {message}",
                end="",
                file=sys.stderr,
                flush=True,
            )

        level = generate_level(
            width,
            height,
            seed,
            LEVEL_TOPOLOGY,
            show_progress,
        )
        output_path = OUTPUT_DIRECTORY / level_file_name(level_number)
        write_new_level(level, output_path)
        print(file=sys.stderr)
        print(f"{output_path} ({width}x{height}, seed={seed})")
    return 0


def main() -> int:
    """Run one append-only batch and always synchronize completed output."""
    exit_code = 0
    try:
        exit_code = generate_batch()
    except KeyboardInterrupt:
        print("\nGeneration cancelled; completed levels were kept.", file=sys.stderr)
        exit_code = 130
    except Exception:
        print(file=sys.stderr)
        raise
    finally:
        refresh_runtime_catalog(GAME_PROJECT_PATH, OUTPUT_DIRECTORY)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
