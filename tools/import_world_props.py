"""Import the nineteen approved static props without changing their pixels."""

import copy
import json
import shutil
import uuid
from pathlib import Path

from PIL import Image

from theme_assets import PROJECT, ROOT, append_entries, read_resource, register_resources, write_resource


SOURCE = ROOT / ".temp/forest_world_study"
CATALOG = PROJECT / "datafiles/world_props/catalog.json"
SPRITE_FOLDER = {"name": "LargeObjects", "path": "folders/Sprites/LargeObjects.yy"}


def register_sprite_folder() -> None:
    """Keep imported prop art in its own GameMaker asset-browser folder."""
    project_file = PROJECT / "RandomForest.yyp"
    project = read_resource(project_file)
    if any(folder["folderPath"] == SPRITE_FOLDER["path"] for folder in project["Folders"]):
        return
    append_entries(project_file, "Folders", [{"$GMFolder": "", "%Name": SPRITE_FOLDER["name"],
        "folderPath": SPRITE_FOLDER["path"], "name": SPRITE_FOLDER["name"],
        "resourceType": "GMFolder", "resourceVersion": "2.0"}])


def import_sprite(name: str, source: Path, origin: list[int]) -> tuple[str, str]:
    """Create a single-frame sprite while copying both PNG layers byte for byte."""
    meta = copy.deepcopy(read_resource(PROJECT / "sprites/sPlayerIdle/sPlayerIdle.yy"))
    with Image.open(source) as image:
        width, height = image.size
        bounds = image.getbbox()
    frame_id = str(uuid.uuid5(uuid.NAMESPACE_URL, name + "/frame"))
    layer_id = str(uuid.uuid5(uuid.NAMESPACE_URL, name + "/layer"))
    meta.update(name=name, **{"%Name": name}, width=width, height=height, origin=9,
                bbox_left=bounds[0], bbox_top=bounds[1], bbox_right=bounds[2] - 1,
                bbox_bottom=bounds[3] - 1, bboxMode=0, collisionKind=1)
    meta["parent"] = dict(SPRITE_FOLDER)
    frame = copy.deepcopy(meta["frames"][0])
    frame.update(name=frame_id, **{"%Name": frame_id})
    meta["frames"] = [frame]
    meta["layers"] = [meta["layers"][0]]
    meta["layers"][0].update(name=layer_id, **{"%Name": layer_id})
    sequence = meta["sequence"]
    sequence.update(name=name, **{"%Name": name}, length=1.0, playbackSpeed=0.0,
                    xorigin=origin[0], yorigin=origin[1])
    key = copy.deepcopy(sequence["tracks"][0]["keyframes"]["Keyframes"][0])
    key.update(Key=0.0, id=str(uuid.uuid5(uuid.NAMESPACE_URL, name + "/key")))
    key["Channels"]["0"]["Id"] = {"name": frame_id, "path": f"sprites/{name}/{name}.yy"}
    sequence["tracks"][0]["keyframes"]["Keyframes"] = [key]
    directory = PROJECT / "sprites" / name
    write_resource(directory / (name + ".yy"), meta)
    layer = directory / "layers" / frame_id
    layer.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, directory / (frame_id + ".png"))
    shutil.copyfile(source, layer / (layer_id + ".png"))
    return "sprites", name


def main() -> None:
    """Publish stable prop definitions and register their native GameMaker resources."""
    register_sprite_folder()
    manifest = json.loads((SOURCE / "setpieces/extracted/manifest.json").read_text())
    definitions, resources = [], []
    for asset in manifest["assets"]:
        base = "sWorldProp" + "".join(word.title() for word in asset["slug"].split("_"))
        variants = {}
        for theme, variant in asset["variants"].items():
            name = base + ("" if theme == "day" else theme.title())
            resources.append(import_sprite(name, SOURCE / variant["sprite"], asset["origin"]))
            frame = read_resource(PROJECT / f"sprites/{name}/{name}.yy")["frames"][0]["name"]
            variants[theme] = {"sprite": name, "image": f"sprites/{name}/{frame}.png"}
        definitions.append({key: asset[key] for key in ("slug", "name", "width", "height", "origin")} | {"variants": variants})
    write_resource(CATALOG, {"props": definitions})
    register_resources(resources)
    project_file = PROJECT / "RandomForest.yyp"
    project = read_resource(project_file)
    if not any(item["name"] == "catalog.json" and item["filePath"] == "datafiles/world_props"
               for item in project["IncludedFiles"]):
        append_entries(project_file, "IncludedFiles", [{"$GMIncludedFile": "", "%Name": "catalog.json",
            "CopyToMask": -1, "filePath": "datafiles/world_props", "name": "catalog.json",
            "resourceType": "GMIncludedFile", "resourceVersion": "2.0"}])
    print(f"Imported {len(definitions)} props, {len(resources)} unchanged PNGs")


if __name__ == "__main__":
    main()
