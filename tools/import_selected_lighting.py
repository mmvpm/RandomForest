"""Install approved E4/EV2 and M4/MO1 banks, preserving the editor-selected night sword."""

import copy
import shutil

from PIL import Image

from lighting_assets import (PROJECT, ACTORS, ENVIRONMENT, TILESETS, SELECTIONS,
                             bank_frames, copy_frames, themed_name, pixel_digest)
from theme_assets import ROOT, read_resource, write_resource, register_resources

ACTOR_BANK = ROOT / ".temp/actor_lighting_study/project"
ENVIRONMENT_BANK = ROOT / ".temp/daylight_palette_study/project"


def verify_sources():
    """Reject stale studies before touching assets changed since the visual review."""
    for name in [*ACTORS, *ENVIRONMENT]:
        bank = ACTOR_BANK if name in ACTORS else ENVIRONMENT_BANK
        old = bank_frames(bank, name)
        current = bank_frames(PROJECT, name)
        assert len(old) == len(current), (name, "Source animation changed")
        for a, b in zip(old, current, strict=True):
            with Image.open(a) as x, Image.open(b) as y:
                assert x.size == y.size and x.convert("RGBA").tobytes() == y.convert("RGBA").tobytes(), (name, "Source art changed")


def import_selection(suffix, environment, actors):
    """Copy one accepted world and all its animations, with ordinary canonical names."""
    resources = []
    for base in [*ENVIRONMENT, *ACTORS]:
        bank = ENVIRONMENT_BANK if base in ENVIRONMENT else ACTOR_BANK
        code = environment if base in ENVIRONMENT else actors
        copy_frames(base, themed_name(base, suffix), bank_frames(bank, themed_name(base, code)))
        resources.append(("sprites", themed_name(base, suffix)))
    for base in TILESETS:
        meta = copy.deepcopy(read_resource(PROJECT / f"tilesets/{base}/{base}.yy"))
        name = base + suffix
        sprite = meta["spriteId"]["name"] + suffix
        meta["name"] = meta["%Name"] = name
        meta["spriteId"] = dict(name=sprite, path=f"sprites/{sprite}/{sprite}.yy")
        write_resource(PROJECT / f"tilesets/{name}/{name}.yy", meta)
        shutil.copyfile(ENVIRONMENT_BANK / f"tilesets/{base + environment}/output_tileset.png",
                        PROJECT / f"tilesets/{name}/output_tileset.png")
        resources.append(("tilesets", name))
    return resources


def main():
    """Import checked final art without runtime shaders or dependencies on study folders."""
    verify_sources()
    record_selection()
    resources = []
    for choice in SELECTIONS:
        resources += import_selection(*choice)
    # The selected night sword is authored in GameMaker, outside these lighting banks.
    copy_frames("sSwordBloom", "sSwordBloomNight", bank_frames(PROJECT, "sSwordBloom"))
    register_resources(resources + [("sprites", "sSwordBloomNight")])
    print("Installed E4/EV2, M4/MO1, exact-mask dark flying sword and unchanged day bloom")


def record_selection():
    """Persist approval fingerprints so audits never depend on disposable study folders."""
    sprites, tilesets = {}, {}
    for suffix, environment, actors in SELECTIONS:
        for base in [*ENVIRONMENT, *ACTORS]:
            bank = ENVIRONMENT_BANK if base in ENVIRONMENT else ACTOR_BANK
            code = environment if base in ENVIRONMENT else actors
            sprites[themed_name(base, suffix)] = pixel_digest(bank_frames(bank, themed_name(base, code)))
        for base in TILESETS:
            tilesets[base + suffix] = pixel_digest([ENVIRONMENT_BANK / f"tilesets/{base + environment}/output_tileset.png"])
    for name in ("sPlayerDarkTapSword", "sSwordBloomNight"):
        paths = bank_frames(PROJECT, "sSwordBloom" if name == "sSwordBloomNight" else name)
        sprites[name] = pixel_digest(paths)
    write_resource(ROOT / "tools/lighting_selection.json", {
        "selection": {"Evening": "E4 Blue Hour + EV2 Light and Shadows", "Morning": "M4 Golden Mist + MO1 Diffuse Light"},
        "sprites": sprites, "tilesets": tilesets,
        "night_sword_rgb": read_resource(ROOT / "tools/lighting_selection.json")["night_sword_rgb"],
        "night_bloom_source": "sSwordBloom"})


if __name__ == "__main__":
    main()
