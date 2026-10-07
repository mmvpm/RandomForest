"""Selected lighting asset names and pixel-preserving GameMaker resource copies."""

import copy
import hashlib
import shutil
import uuid

from PIL import Image

from theme_assets import PROJECT, read_resource, write_resource

PLAYER = ["sPlayer" + state for state in ("Idle", "Blink", "Wondering", "Move", "Jump", "Fall",
          "Attack1", "Attack2", "Attack3", "Hurt", "Die", "LightStomp", "LightTransform", "LightTurn")]
ENEMIES = {"slime": ["sSlime" + state for state in ("Idle", "Move", "Attack", "Hurt", "Die", "Bloom")],
           "skeleton": ["sSkeleton" + state for state in ("Idle", "Move", "React", "Attack", "Hurt", "Die", "Bloom")],
           "bungalo": ["sBungalo" + state for state in ("Idle", "Move", "Attack", "Hurt", "Die", "Charge", "Trans", "Bloom")]}
EFFECTS = ["sPlayerFxLight", "sPlayerFxLightToDark", "sPlayerFxDarkToLight", "sPlayerBloom", "sPlayerBloom2",
           "sSwordBloom", "sPlayerJumpEffect", "sPlayerLandingEffect", "sAirBack", "sAirBurst",
           "sTapDestroy", "sTeleportStart", "sTeleportEnd", "sTapArrow", "sTapArrowDiag",
           "sTapCountdown", "sTapCountdownDiag"]
ACTORS = [*PLAYER, *(name for names in ENEMIES.values() for name in names), "sPlayerTapSword", *EFFECTS]
ENVIRONMENT = ["sBackground", "sBackground_x13", "sPlatforms", "sSpikes", "sSpikesExt", "sStar", "sBorder3", "sBorder4"]
TILESETS = ["tsPlatforms", "tsSpikes", "tsSpikesExt"]
SELECTIONS = [("Evening", "E4", "EV2"), ("Morning", "M4", "MO1")]


def themed_name(base, suffix):
    """Keep the background resolution postfix after the lighting suffix."""
    return "sBackground" + suffix + "_x13" if base == "sBackground_x13" else base + suffix


def clone_metadata(original, target):
    """Change resource IDs only; every mask, sequence and editor setting is retained."""
    meta = copy.deepcopy(original)
    meta["name"] = meta["%Name"] = meta["sequence"]["name"] = meta["sequence"]["%Name"] = target
    frames = {f["name"]: str(uuid.uuid5(uuid.NAMESPACE_URL, target + f["name"])) for f in original["frames"]}
    layers = {l["name"]: str(uuid.uuid5(uuid.NAMESPACE_URL, target + l["name"])) for l in original["layers"]}
    for frame in meta["frames"]:
        frame["name"] = frame["%Name"] = frames[frame["name"]]
    for layer in meta["layers"]:
        layer["name"] = layer["%Name"] = layers[layer["name"]]
    for track in meta["sequence"]["tracks"]:
        for key in track.get("keyframes", {}).get("Keyframes", []):
            key["id"] = str(uuid.uuid5(uuid.NAMESPACE_URL, target + key["id"]))
            for channel in key["Channels"].values():
                if "Id" in channel:
                    channel["Id"] = dict(name=frames[channel["Id"]["name"]], path=f"sprites/{target}/{target}.yy")
    return meta


def copy_frames(base, target, images):
    """Install already approved PNGs; never re-encode or filter their pixel data."""
    original = read_resource(PROJECT / f"sprites/{base}/{base}.yy")
    path = PROJECT / f"sprites/{target}/{target}.yy"
    meta = read_resource(path) if path.exists() else clone_metadata(original, target)
    assert len(images) == len(meta["frames"]) == len(original["frames"])
    assert len(meta["layers"]) == 1
    if not path.exists():
        write_resource(path, meta)
    for source, frame in zip(images, meta["frames"], strict=True):
        outputs = [path.parent / (frame["name"] + ".png")]
        outputs += [path.parent / "layers" / frame["name"] / (layer["name"] + ".png") for layer in meta["layers"]]
        for output in outputs:
            output.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, output)


def bank_frames(bank, name):
    """Return palette-bank frames in actual animation order."""
    directory = bank / "sprites" / name
    meta = read_resource(directory / (name + ".yy"))
    return [directory / (frame["name"] + ".png") for frame in meta["frames"]]


def pixel_digest(paths):
    """Fingerprint ordered RGBA pixels and dimensions, independently of PNG encoding."""
    digest = hashlib.sha256()
    for path in paths:
        with Image.open(path) as image:
            digest.update(image.width.to_bytes(4, "big"))
            digest.update(image.height.to_bytes(4, "big"))
            digest.update(image.convert("RGBA").tobytes())
    return digest.hexdigest()
