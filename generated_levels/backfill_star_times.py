#!/usr/bin/env python3
"""Add calculated star thresholds to bundled challenge JSON files."""

from __future__ import annotations

import json
from pathlib import Path

from challenge_batch import list_level_paths
from procedural.star_times import calculate_star_times


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CHALLENGE_DIRECTORY = (
    PROJECT_ROOT / "RandomForest" / "datafiles" / "challenge_levels"
)


def add_missing_star_times(level_path: Path) -> bool:
    """Add timing metadata without changing existing semantic level fields."""
    level = json.loads(level_path.read_text(encoding="utf-8"))
    if "star_times" in level:
        return False
    level["star_times"] = calculate_star_times(level)
    level_path.write_text(
        json.dumps(level, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return True


def main() -> None:
    """Backfill every bundled numeric challenge exactly once."""
    updated = 0
    for level_path in list_level_paths(CHALLENGE_DIRECTORY):
        updated += add_missing_star_times(level_path)
    print(f"Added star_times to {updated} challenge levels.")


if __name__ == "__main__":
    main()
