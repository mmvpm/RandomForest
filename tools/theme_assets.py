"""Prepare theme references and import pixel-preserving GameMaker resources."""

import argparse
import copy
import json
import re
import uuid
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "RandomForest"
WORK = ROOT / ".temp" / "night_art"
FAMILIES = {
    "slime": ["sSlime" + state for state in ("Idle", "Move", "Attack", "Hurt", "Die", "Bloom")],
    "skeleton": ["sSkeleton" + state for state in ("Idle", "React", "Move", "Attack", "Hurt", "Die", "Bloom")],
    "bungalo": ["sBungalo" + state for state in ("Idle", "Move", "Attack", "Hurt", "Die", "Charge", "Trans", "Bloom")],
    "platforms": ["sPlatforms"],
    "spikes": ["sSpikes"],
    "spikes_ext": ["sSpikesExt"],
    "ui_star": ["sStar"],
    "ui_panel3": ["sBorder3"],
    "ui_panel4": ["sBorder4"],
    "pointer": ["sPointer"],
    "teleport_start": ["sTeleportStart"],
    "teleport_end": ["sTeleportEnd"],
    "air_back": ["sAirBack"],
    "air_burst": ["sAirBurst"],
    "tap_destroy": ["sTapDestroy"],
}


def read_resource(path):
    """Read GameMaker JSON, including legacy trailing commas."""
    return json.loads(re.sub(r",\s*([}\]])", r"\1", path.read_text()))


def write_resource(path, resource):
    """Write one GameMaker resource as regular JSON."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(resource, ensure_ascii=False, indent=2) + "\n")


def sprite_resource(name):
    """Read a sprite's original metadata without modifying it."""
    return read_resource(PROJECT / "sprites" / name / (name + ".yy"))


def sprite_frames(name):
    """Load composite frames in their animation order."""
    resource = sprite_resource(name)
    return [Image.open(PROJECT / "sprites" / name / (f["name"] + ".png")).convert("RGBA")
            for f in resource["frames"]]


def prepare_references():
    """Pack original frames into readable, nearest-neighbor imagegen inputs."""
    WORK.mkdir(parents=True, exist_ok=True)
    for family, names in FAMILIES.items():
        rows = []
        for name in names:
            frames = sprite_frames(name)
            for start in range(0, len(frames), 8):
                rows.append((name, start, frames[start:start + 8]))
        width = max(sum(frame.width + 5 for frame in frames) for _, _, frames in rows) + 10
        height = sum(max(frame.height for frame in frames) + 16 for _, _, frames in rows)
        atlas = Image.new("RGBA", (width, height))
        draw = ImageDraw.Draw(atlas)
        y = 0
        for name, start, frames in rows:
            draw.text((3, y), f"{name} {start}-{start + len(frames) - 1}", fill=(210, 210, 230, 255))
            x = 5
            for frame in frames:
                atlas.paste(frame, (x, y + 13))
                x += frame.width + 5
            y += max(frame.height for frame in frames) + 16
        atlas = atlas.resize((width * 3, height * 3), Image.Resampling.NEAREST)
        atlas.save(WORK / (family + "-source.png"))
        print(f"Reference {family}: {atlas.size}")


def clone_sprite(source_name, target_name, images):
    """Clone every sprite setting, including collision masks, with new resource IDs."""
    resource = copy.deepcopy(sprite_resource(source_name))
    resource["name"] = resource["%Name"] = target_name
    resource["sequence"]["name"] = resource["sequence"]["%Name"] = target_name
    ids = {f["name"]: str(uuid.uuid5(uuid.NAMESPACE_URL, target_name + f["name"])) for f in resource["frames"]}
    layers = {layer["name"]: str(uuid.uuid5(uuid.NAMESPACE_URL, target_name + layer["name"])) for layer in resource["layers"]}
    for frame in resource["frames"]:
        frame["name"] = frame["%Name"] = ids[frame["name"]]
    for layer in resource["layers"]:
        layer["name"] = layer["%Name"] = layers[layer["name"]]
    for track in resource["sequence"]["tracks"]:
        for key in track.get("keyframes", {}).get("Keyframes", []):
            key["id"] = str(uuid.uuid5(uuid.NAMESPACE_URL, target_name + key["id"]))
            for channel in key["Channels"].values():
                if "Id" in channel:
                    channel["Id"] = {"name": ids[channel["Id"]["name"]],
                                     "path": f"sprites/{target_name}/{target_name}.yy"}
    save_sprite(target_name, resource, images)
    return resource


def save_sprite(name, resource, images):
    """Save matching composite and editable-layer PNGs for each frame."""
    directory = PROJECT / "sprites" / name
    metadata = directory / (name + ".yy")
    if not metadata.exists() or read_resource(metadata) != resource:
        write_resource(metadata, resource)
    for frame, image in zip(resource["frames"], images, strict=True):
        if image.size != (resource["width"], resource["height"]):
            raise ValueError(f"Wrong frame dimensions: {name}")
        image.save(directory / (frame["name"] + ".png"))
        layer_dir = directory / "layers" / frame["name"]
        layer_dir.mkdir(parents=True, exist_ok=True)
        # These sprites have one editable layer; preserve its pixel alpha exactly.
        for layer in resource["layers"]:
            image.save(layer_dir / (layer["name"] + ".png"))


def import_backgrounds():
    """Import each provided background and an independent morning day-copy."""
    sources = {"": ROOT / ".temp/background/Итог_темнее.png",
               "Evening": ROOT / ".temp/images/Итог.png",
               "Night": ROOT / ".temp/background/Ночь_итог.jpg",
               "Morning": ROOT / ".temp/background/Итог_темнее.png"}
    names = []
    for suffix, source in sources.items():
        image = Image.open(source).convert("RGBA").crop((0, 0, 624, 351))
        for base, frame in [("sBackground", image.resize((480, 270), Image.Resampling.NEAREST)),
                            ("sBackground_x13", image)]:
            target = "sBackground" + suffix + ("_x13" if base.endswith("_x13") else "")
            if not suffix:
                save_sprite(base, sprite_resource(base), [frame])
            else:
                clone_sprite(base, target, [frame])
                names.append(("sprites", target))
    return names


def recolor(image, palette, bloom=None, grass_palette=None):
    """Replace RGB only, keeping every original alpha value and pixel position."""
    def pixel_value(index, pixel):
        """Apply the approved material palette or the matching bloom tint."""
        red, green, blue, alpha = pixel
        if alpha == 0:
            return pixel
        if bloom:
            return (*bloom, alpha)
        key = f"{red},{green},{blue}"
        if key not in palette:
            raise ValueError(f"Missing source color: {key}")
        if grass_palette:
            x, y = index % image.width, index // image.width
            row, column = y // 13, x // 13
            grass = (row == 4 and column >= 6 or row == 5 and column >= 5
                     or row == 6 and column >= 5 and y % 13 < 3)
            if grass:
                return (*grass_palette[key], alpha)
        return (*palette[key], alpha)
    output = Image.new("RGBA", image.size)
    output.putdata([pixel_value(index, pixel) for index, pixel in enumerate(image.get_flattened_data())])
    return output


def packed_tileset(resource, source, template):
    """Pack tiles with extruded borders; retain GameMaker's empty first tile."""
    output = template.copy()
    width, height = resource["tileWidth"], resource["tileHeight"]
    border_x, border_y = resource["out_tilehborder"], resource["out_tilevborder"]
    stride_x, stride_y = width + border_x * 2, height + border_y * 2
    columns = (source.width - resource["tilexoff"] + resource["tilehsep"]) // (width + resource["tilehsep"])
    for index in range(1, resource["tile_count"]):
        source_x = resource["tilexoff"] + index % columns * (width + resource["tilehsep"])
        source_y = resource["tileyoff"] + index // columns * (height + resource["tilevsep"])
        target_x = index % resource["out_columns"] * stride_x
        target_y = index // resource["out_columns"] * stride_y
        for y in range(stride_y):
            for x in range(stride_x):
                pixel = source.getpixel((source_x + min(width - 1, max(0, x - border_x)),
                                         source_y + min(height - 1, max(0, y - border_y))))
                output.putpixel((target_x + x, target_y + y), pixel)
    return output


def import_night(palettes):
    """Build exact-geometry night sprite and tileset siblings from approved palettes."""
    entries = []
    for family, names in FAMILIES.items():
        colors = palettes[family]["colors"]
        for name in names:
            images = [recolor(frame, colors, palettes[family].get("bloom") if name.endswith("Bloom") else None,
                             palettes[family].get("grass") if name == "sPlatforms" else None)
                      for frame in sprite_frames(name)]
            clone_sprite(name, name + "Night", images)
            entries.append(("sprites", name + "Night"))
    for name in ("tsPlatforms", "tsSpikes", "tsSpikesExt"):
        resource = read_resource(PROJECT / "tilesets" / name / (name + ".yy"))
        target = name + "Night"
        resource["name"] = resource["%Name"] = target
        sprite = resource["spriteId"]["name"] + "Night"
        resource["spriteId"] = {"name": sprite, "path": f"sprites/{sprite}/{sprite}.yy"}
        write_resource(PROJECT / "tilesets" / target / (target + ".yy"), resource)
        template = Image.open(PROJECT / "tilesets" / name / "output_tileset.png").convert("RGBA")
        packed_tileset(resource, sprite_frames(sprite)[0], template).save(
            PROJECT / "tilesets" / target / "output_tileset.png")
        entries.append(("tilesets", target))
    return entries


def register_resources(entries):
    """Register new resources once while preserving project and editor ordering."""
    path = PROJECT / "RandomForest.yyp"
    project = read_resource(path)
    known = {entry["id"]["name"] for entry in project["resources"]}
    additions = []
    for kind, name in entries:
        if name not in known:
            additions.append({"id": {"name": name, "path": f"{kind}/{name}/{name}.yy"}})
            known.add(name)
    append_entries(path, "resources", additions)
    order_path = PROJECT / "RandomForest.resource_order"
    order = read_resource(order_path)
    known = {entry["name"] for entry in order["ResourceOrderSettings"]}
    additions = []
    for kind, name in entries:
        if name not in known:
            additions.append({"name": name, "order": len(known), "path": f"{kind}/{name}/{name}.yy"})
            known.add(name)
    append_entries(order_path, "ResourceOrderSettings", additions)


def append_entries(path, section, entries):
    """Append resource lines without reformatting unrelated project metadata."""
    if not entries:
        return
    text = path.read_text()
    pattern = r'("' + section + r'"\s*:\s*\[)(.*?)(\n  \])'
    def insert(match):
        """Keep the old array body and append valid trailing-comma entries."""
        body = match[2].rstrip()
        if body and not body.endswith(","):
            body += ","
        rows = ["    " + json.dumps(entry, separators=(",", ":")) + "," for entry in entries]
        return match[1] + body + "\n" + "\n".join(rows) + match[3]
    updated, count = re.subn(pattern, insert, text, count=1, flags=re.S)
    if count != 1:
        raise ValueError(f"Missing project section: {section}")
    path.write_text(updated)


def main():
    """Prepare references or import the reviewed theme art."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("references", "import"))
    parser.add_argument("--palettes", type=Path)
    args = parser.parse_args()
    if args.action == "references":
        prepare_references()
    else:
        if args.palettes is None:
            parser.error("import requires --palettes")
        entries = import_backgrounds() + import_night(json.loads(args.palettes.read_text()))
        register_resources(entries + [("scripts", name) for name in
                                      ("scriptLevelThemes", "scriptMenuBackground", "scriptThemePresentation", "scriptThemeUiDraw")])
        print(f"Imported {len(entries)} new theme resources")


if __name__ == "__main__":
    main()
