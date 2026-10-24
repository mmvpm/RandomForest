#!/usr/bin/env python3
"""Validate manually edited generated-level JSON files."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

try:
    from .procedural.validation import validate_level
except ImportError:
    from procedural.validation import validate_level


def parse_arguments() -> argparse.Namespace:
    """Read level files or directories selected for validation."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "paths",
        nargs="+",
        type=Path,
        help="Level JSON files or directories containing numbered level files.",
    )
    return parser.parse_args()


def collect_level_paths(inputs: list[Path]) -> list[Path]:
    """Expand inputs into a stable unique list of numeric level files."""
    paths: list[Path] = []
    for input_path in inputs:
        if input_path.is_dir():
            paths.extend(
                path
                for path in input_path.glob("*.json")
                if path.stem.isdigit()
            )
        else:
            paths.append(input_path)
    return sorted(set(paths), key=lambda path: (path.parent, path.name))


def main() -> int:
    """Validate every selected level and print one confirmation per file."""
    paths = collect_level_paths(parse_arguments().paths)
    if not paths:
        raise ValueError("No numbered level JSON files were selected")
    for path in paths:
        level = json.loads(path.read_text(encoding="utf-8"))
        validate_level(level)
        print(f"{path}: valid")
    print(f"Validated {len(paths)} level(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
