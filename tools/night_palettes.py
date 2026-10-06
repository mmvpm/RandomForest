"""Record imagegen-derived material palettes without changing source pixel geometry."""

import json
from pathlib import Path

from theme_assets import FAMILIES, WORK, sprite_frames


# Colours sampled from the reviewed imagegen designs; shared ramps prevent flicker.
SLIME = {
    (18, 53, 27): (0, 27, 49), (25, 76, 38): (0, 46, 73),
    (38, 115, 58): (6, 77, 105), (58, 174, 88): (14, 152, 160),
    (66, 192, 98): (64, 207, 198), (171, 41, 63): (77, 164, 177),
    (232, 70, 70): (153, 234, 215), (245, 120, 120): (208, 255, 234),
}
SKELETON = {
    (37, 35, 41): (18, 21, 48), (59, 59, 77): (30, 37, 73),
    (62, 70, 82): (48, 57, 105), (97, 94, 112): (60, 80, 140),
    (150, 140, 148): (96, 121, 186), (189, 179, 172): (138, 166, 224),
    (247, 236, 213): (164, 197, 242), (255, 255, 255): (197, 221, 248),
}
SPIKES = {
    (9, 15, 6): (9, 9, 22), (73, 14, 42): (34, 26, 50),
    (132, 15, 70): (82, 57, 101), (204, 32, 113): (158, 111, 170),
}
# Approved C / Smoky Heather: exact ramps from the engine-rendered colour study.
HEATHER_TERRAIN = {
    (7, 11, 25): (9, 9, 22),
    (9, 19, 32): (14, 13, 26),
    (11, 16, 34): (14, 13, 26),
    (12, 18, 38): (16, 15, 28),
    (13, 18, 39): (16, 15, 29),
    (14, 19, 41): (17, 16, 30),
    (15, 21, 45): (19, 18, 32),
    (18, 25, 52): (23, 21, 35),
    (19, 27, 54): (26, 23, 38),
    (19, 27, 56): (28, 25, 39),
    (19, 56, 67): (38, 32, 47),
    (19, 57, 68): (39, 32, 47),
    (20, 28, 56): (29, 25, 40),
    (20, 28, 57): (29, 26, 40),
    (21, 29, 59): (32, 28, 43),
    (21, 30, 60): (33, 29, 44),
    (22, 32, 62): (34, 30, 45),
    (22, 68, 78): (44, 37, 53),
    (25, 36, 67): (36, 32, 47),
    (26, 37, 70): (37, 33, 48),
    (27, 85, 92): (52, 44, 62),
    (28, 86, 93): (53, 45, 62),
    (28, 87, 94): (53, 45, 63),
    (30, 94, 101): (57, 49, 67),
    (31, 44, 79): (41, 36, 52),
    (32, 46, 81): (42, 36, 53),
    (32, 99, 105): (60, 51, 69),
    (33, 47, 84): (43, 37, 54),
    (36, 115, 119): (67, 58, 78),
    (36, 116, 120): (68, 58, 78),
    (37, 53, 91): (46, 40, 57),
    (39, 125, 128): (72, 62, 83),
    (41, 59, 99): (51, 44, 62),
    (42, 60, 100): (52, 45, 63),
    (43, 61, 101): (52, 46, 64),
    (43, 62, 102): (53, 46, 64),
    (44, 63, 104): (54, 47, 66),
    (52, 74, 116): (62, 54, 74),
    (52, 140, 136): (80, 70, 90),
    (53, 142, 136): (81, 71, 91),
    (55, 144, 137): (82, 72, 92),
    (58, 147, 139): (83, 73, 94),
    (60, 86, 132): (73, 63, 85),
    (62, 152, 141): (86, 76, 96),
    (66, 94, 142): (79, 69, 92),
    (73, 108, 153): (87, 77, 101),
    (74, 111, 155): (89, 79, 102),
    (76, 169, 150): (95, 85, 105),
    (78, 171, 150): (96, 86, 106),
    (82, 126, 167): (98, 88, 112),
    (85, 134, 173): (103, 93, 117),
    (87, 137, 175): (104, 95, 119),
    (97, 159, 192): (117, 108, 132),
    (99, 196, 163): (109, 99, 118),
}
STAR = [(35, (30, 26, 40)), (105, (64, 54, 78)), (169, (126, 114, 146)),
        (194, (151, 140, 172)), (214, (177, 169, 190)), (222, (191, 181, 199))]


def interpolate(value, anchors):
    """Preserve intermediate source shades with one continuous reviewed ramp."""
    for (low, start), (high, end) in zip(anchors, anchors[1:]):
        if value <= high:
            t = max(0, min(1, (value - low) / (high - low)))
            return tuple(round(a + (b - a) * t) for a, b in zip(start, end))
    return anchors[-1][1]


def palette_color(family, color):
    """Map each material's source colour into its reviewed nocturnal design."""
    if family == "slime":
        return SLIME[color]
    if family == "skeleton":
        return SKELETON[color]
    if family.startswith("spikes"):
        return SPIKES[color]
    if family == "bungalo":
        if min(color) > 180:
            return (225, 208, 243)
        return interpolate(color[0], [(55, (13, 7, 39)), (118, (37, 26, 80)),
                                     (188, (123, 84, 202)), (255, (192, 158, 232))])
    if family == "ui_star":
        return interpolate(color[1], STAR)
    if family.startswith("ui_panel"):
        return {(0, 0, 0): (0, 0, 0), (24, 24, 24): (17, 19, 25),
                (60, 60, 60): (31, 33, 39), (248, 240, 224): (220, 220, 220)}[color]
    if family == "pointer":
        return interpolate(color[0], [(0, (6, 7, 16)), (32, (22, 23, 40)),
                                     (72, (44, 45, 67)), (92, (64, 64, 88)),
                                     (160, (107, 111, 143)), (255, (161, 172, 206))])
    if family in ("teleport_start", "teleport_end", "air_back", "air_burst", "tap_destroy"):
        return interpolate(color[1], [(0, (18, 14, 38)), (130, (77, 62, 136)),
                                     (167, (123, 113, 202)), (202, (166, 165, 238)),
                                     (218, (222, 218, 255))])
    return platform_color(color)


def platform_color(color, grass=False):
    """Match the approved preview exactly, including previously quantized shade collisions."""
    previous = [(15, (7, 11, 25)), (59, (17, 49, 61)),
                (136, (39, 125, 128)), (178, (99, 196, 163))] if grass else [
        (15, (7, 11, 25)), (30, (18, 25, 52)), (59, (21, 30, 60)),
        (84, (37, 53, 91)), (136, (66, 94, 142)), (178, (97, 159, 192))]
    # Export also includes unused grass shades; their ramp must remain defined.
    fallback = [(15, (9, 9, 22)), (59, (35, 29, 43)),
                (136, (72, 62, 83)), (178, (109, 99, 118))] if grass else [
        (15, (9, 9, 22)), (30, (23, 21, 35)), (59, (33, 29, 44)),
        (84, (46, 40, 57)), (136, (79, 69, 92)), (178, (117, 108, 132))]
    return HEATHER_TERRAIN.get(interpolate(color[1], previous), interpolate(color[1], fallback))


def main():
    """Write complete RGB lookup tables for every nontransparent source colour."""
    result = {}
    glow = {"slime": [55, 193, 184], "skeleton": [108, 145, 215], "bungalo": [159, 100, 230]}
    for family, names in FAMILIES.items():
        colors = set()
        for name in names:
            if name.endswith("Bloom"):
                continue
            for image in sprite_frames(name):
                colors.update(pixel[:3] for pixel in image.get_flattened_data() if pixel[3] > 0)
        result[family] = {"colors": {",".join(map(str, color)): palette_color(family, color)
                                      for color in sorted(colors)}}
        if family in glow:
            result[family]["bloom"] = glow[family]
        if family == "platforms":
            result[family]["grass"] = {",".join(map(str, color)): platform_color(color, grass=True)
                for color in sorted(colors)}
    output = WORK / "palettes.json"
    output.write_text(json.dumps(result, indent=2) + "\n")
    print(f"Saved {sum(len(value['colors']) for value in result.values())} RGB replacements: {output}")


if __name__ == "__main__":
    main()
