"""Slightly mute the purple Root Maw from an explicit, unchanged source directory."""

import argparse
from pathlib import Path

from PIL import Image

from theme_assets import PROJECT

BRIGHTNESS = 0.92
SATURATION = 0.90
HURT_FLASH_COLOUR = (219, 221, 236)


def mute_frame(source, destination):
    """Keep alpha and the pixel grid intact while lowering brightness and saturation."""
    image = Image.open(source).convert("RGBA")
    pixels = []
    for red, green, blue, alpha in image.get_flattened_data():
        # Damage feedback keeps its original near-white even when the skin is muted.
        if (red, green, blue) == HURT_FLASH_COLOUR:
            pixels.append((red, green, blue, alpha))
            continue
        gray = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        rgb = [round((gray + (channel - gray) * SATURATION) * BRIGHTNESS)
               for channel in (red, green, blue)]
        pixels.append((*rgb, alpha))
    image.putdata(pixels)
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination)


def main():
    """Rebuild only purple artwork; require a separate source to avoid repeated dimming."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True,
                        help="Original sprite directories, preserved before the first run")
    args = parser.parse_args()
    if args.source.resolve() == (PROJECT / "sprites").resolve():
        parser.error("Use an unchanged copy of the source, not the output directory")
    count = 0
    for folder in sorted(args.source.glob("sRootMaw*")):
        if folder.name.endswith("N5") or folder.name == "sRootMawCollision":
            continue
        for source in folder.rglob("*.png"):
            mute_frame(source, PROJECT / "sprites" / source.relative_to(args.source))
            count += 1
    print(f"Muted {count} frame/layer images; alpha, origins and animation timing unchanged.")


if __name__ == "__main__":
    main()
