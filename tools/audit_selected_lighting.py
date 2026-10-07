"""Check every selected frame, original collision contract and packed runtime tile."""

from PIL import Image

from audit_theme_assets import audit_sprite, equal_pixels
from lighting_assets import ACTORS, ENVIRONMENT, TILESETS, SELECTIONS, bank_frames, pixel_digest, themed_name
from theme_assets import PROJECT, ROOT, packed_tileset, read_resource, sprite_frames


def audit_tileset(base, suffix, digest):
    """Check original layout, packed edge extrusion and approved output pixels."""
    name = base + suffix
    old = read_resource(PROJECT / f"tilesets/{base}/{base}.yy")
    new = read_resource(PROJECT / f"tilesets/{name}/{name}.yy")
    ignored = {"name", "%Name", "spriteId"}
    assert {k: v for k, v in old.items() if k not in ignored} == {
        k: v for k, v in new.items() if k not in ignored}, (name, "tile layout")
    assert new["spriteId"]["name"] == old["spriteId"]["name"] + suffix
    output = PROJECT / f"tilesets/{name}/output_tileset.png"
    assert pixel_digest([output]) == digest, (name, "approved packed palette")
    with Image.open(PROJECT / f"tilesets/{base}/output_tileset.png") as image:
        original = image.convert("RGBA")
    with Image.open(output) as image:
        actual = image.convert("RGBA")
    assert equal_pixels(original.getchannel("A"), actual.getchannel("A")), (name, "tile alpha")
    assert equal_pixels(actual, packed_tileset(new, sprite_frames(new["spriteId"]["name"])[0], original)), (name, "edge extrusion")


def main():
    """Audit final files without requiring any of the disposable study directories."""
    approved = read_resource(ROOT / "tools/lighting_selection.json")
    resources = read_resource(PROJECT / "RandomForest.yyp")["resources"]
    entries = {r["id"]["name"] for r in resources}
    frames = 0
    for suffix, _, _ in SELECTIONS:
        for base in [*ENVIRONMENT, *ACTORS]:
            name = themed_name(base, suffix)
            assert name in entries, name
            frames += audit_sprite(base, name)
            assert pixel_digest(bank_frames(PROJECT, name)) == approved["sprites"][name], (name, "approved pixels")
        for base in TILESETS:
            assert base + suffix in entries
            audit_tileset(base, suffix, approved["tilesets"][base + suffix])
    for base, name in [("sPlayerTapSword", "sPlayerDarkTapSword"), ("sSwordBloom", "sSwordBloomNight")]:
        assert name in entries
        audit_sprite(base, name)
        assert pixel_digest(bank_frames(PROJECT, name)) == approved["sprites"][name], (name, "night pixels")
    day, night = sprite_frames("sPlayerTapSword")[0], sprite_frames("sPlayerDarkTapSword")[0]
    for a, b in zip(day.get_flattened_data(), night.get_flattened_data(), strict=True):
        if a[3]:
            assert list(b[:3]) == approved["night_sword_rgb"][",".join(map(str, a[:3]))]
    bloom = sprite_frames("sSwordBloomNight")[0]
    assert all(list(p[:3]) == approved["night_bloom_rgb"] for p in bloom.get_flattened_data() if p[3])
    print(f"PASS: {frames} approved evening/morning frames, complete masks/alpha/origins/timings, six packed tilesets and exact horizontal night sword.")


if __name__ == "__main__":
    main()
