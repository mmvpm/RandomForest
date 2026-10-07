"""Build E2 Copper Evening menu art without changing any gameplay resource."""

from night_palettes import interpolate
from theme_assets import clone_sprite, register_resources, sprite_frames


def copper_color(name, color):
    """Reproduce the reviewed E2 star and panel ramps from the original RGB."""
    if name == "sStar":
        accent = (211, 176, 153)
        ramp = [(shade, tuple(round(v * scale) for v in accent))
                for shade, scale in zip((35, 105, 169, 194, 214, 222),
                                        (0.17, 0.36, 0.70, 0.85, 0.97, 1.03))]
        return interpolate(color[1], ramp)
    return {(0, 0, 0): (0, 0, 0), (24, 24, 24): (25, 21, 31),
            (60, 60, 60): (51, 39, 37), (248, 240, 224): (224, 222, 218)}[color]


def copper_frame(name, frame):
    """Replace visible RGB only, retaining every original pixel and alpha value."""
    result = frame.copy()
    result.putdata([(*copper_color(name, pixel[:3]), pixel[3]) if pixel[3] else pixel
                    for pixel in frame.get_flattened_data()])
    return result


def main():
    """Register three menu-only siblings and their small presentation module."""
    entries = [("scripts", "scriptMenuUiTheme")]
    for name in ("sStar", "sBorder3", "sBorder4"):
        target = name + "MenuEvening"
        clone_sprite(name, target, [copper_frame(name, frame) for frame in sprite_frames(name)])
        entries.append(("sprites", target))
    register_resources(entries)


if __name__ == "__main__":
    main()
