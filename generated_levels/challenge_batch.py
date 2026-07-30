"""Manage the append-only production catalog of generated challenges."""

from __future__ import annotations

import json
import re
from pathlib import Path
from random import Random


CATALOG_FILE_NAME = "catalog.json"
LEVEL_FILE_PATTERN = re.compile(r"(0*[1-9][0-9]*)\.json")
INCLUDED_FILE_PATH = "datafiles/challenge_levels"


def level_file_name(level_number: int) -> str:
    """Return a sequential file name padded to at least two digits."""
    return f"{level_number:02d}.json"


def list_level_paths(output_directory: Path) -> list[Path]:
    """Return numeric challenge files ordered by their level number."""
    if not output_directory.exists():
        return []
    paths = [
        path
        for path in output_directory.iterdir()
        if path.is_file() and LEVEL_FILE_PATTERN.fullmatch(path.name)
    ]
    return sorted(paths, key=lambda path: int(path.stem))


def next_level_number(output_directory: Path) -> int:
    """Return the next number without reusing an existing level name."""
    paths = list_level_paths(output_directory)
    return int(paths[-1].stem) + 1 if paths else 1


def choose_dimensions(
    random_source: Random,
    width_range: tuple[int, int],
    height_range: tuple[int, int],
) -> tuple[int, int]:
    """Choose one level size inside the configured inclusive ranges."""
    return (
        random_source.randint(*width_range),
        random_source.randint(*height_range),
    )


def write_new_level(level: dict[str, object], output_path: Path) -> None:
    """Create one level file without allowing an existing file to be replaced."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    contents = json.dumps(level, ensure_ascii=False, indent=2) + "\n"
    with output_path.open("x", encoding="utf-8") as output_file:
        output_file.write(contents)


def write_catalog(output_directory: Path) -> Path:
    """Rebuild the ordered runtime catalog from append-only level files."""
    output_directory.mkdir(parents=True, exist_ok=True)
    catalog_path = output_directory / CATALOG_FILE_NAME
    catalog = {
        "levels": [
            f"challenge_levels/{path.name}"
            for path in list_level_paths(output_directory)
        ],
    }
    catalog_path.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return catalog_path


def _included_file_line(file_name: str) -> str:
    """Build one GameMaker Included Files project entry."""
    return (
        '    {"$GMIncludedFile":"","%Name":"'
        f'{file_name}","CopyToMask":-1,"filePath":"{INCLUDED_FILE_PATH}",'
        f'"name":"{file_name}","resourceType":"GMIncludedFile",'
        '"resourceVersion":"2.0",},'
    )


def sync_included_files(project_path: Path, output_directory: Path) -> None:
    """Register every challenge JSON as an Included File, idempotently."""
    source = project_path.read_text(encoding="utf-8")
    lines = source.splitlines()
    section_start = lines.index('  "IncludedFiles":[')
    section_end = next(
        index
        for index in range(section_start + 1, len(lines))
        if lines[index] == "  ],"
    )

    retained_entries = [
        line
        for line in lines[section_start + 1 : section_end]
        if f'"filePath":"{INCLUDED_FILE_PATH}"' not in line
    ]
    challenge_names = [CATALOG_FILE_NAME]
    challenge_names.extend(path.name for path in list_level_paths(output_directory))
    challenge_entries = [_included_file_line(name) for name in challenge_names]

    updated_lines = (
        lines[: section_start + 1]
        + retained_entries
        + challenge_entries
        + lines[section_end:]
    )
    project_path.write_text("\n".join(updated_lines) + "\n", encoding="utf-8")


def refresh_runtime_catalog(
    project_path: Path,
    output_directory: Path,
) -> None:
    """Refresh the mutable catalog metadata after generated files change."""
    write_catalog(output_directory)
    sync_included_files(project_path, output_directory)
