"""Verify original collision masks, animation contracts and all imported theme art."""

from PIL import Image

from theme_assets import FAMILIES, PROJECT, packed_tileset, read_resource, sprite_frames, sprite_resource


def equal_pixels(left, right):
    """Compare every pixel byte, including fully transparent pixels."""
    return left.size == right.size and left.tobytes() == right.tobytes()


def audit_sprite(source, target):
    """Check full collision metadata, frame order, sequence settings and source alpha."""
    old, new = sprite_resource(source), sprite_resource(target)
    ignored = {"name", "%Name", "frames", "layers", "sequence"}
    assert {k: v for k, v in old.items() if k not in ignored} == {
        k: v for k, v in new.items() if k not in ignored}, (target, "sprite/mask metadata")
    assert len(old["frames"]) == len(new["frames"]), (target, "frame count")
    ignored_sequence = {"name", "%Name", "tracks"}
    assert {k: v for k, v in old["sequence"].items() if k not in ignored_sequence} == {
        k: v for k, v in new["sequence"].items() if k not in ignored_sequence}, (target, "sequence settings")
    for track_old, track_new in zip(old["sequence"]["tracks"], new["sequence"]["tracks"], strict=True):
        keys_old, keys_new = track_old["keyframes"]["Keyframes"], track_new["keyframes"]["Keyframes"]
        assert len(keys_old) == len(keys_new)
        for key_old, key_new in zip(keys_old, keys_new, strict=True):
            assert {k: v for k, v in key_old.items() if k not in ("id", "Channels")} == {
                k: v for k, v in key_new.items() if k not in ("id", "Channels")}, (target, "frame timing")
            for channel in key_new["Channels"].values():
                frame = new["frames"][int(key_new["Key"])]["name"]
                assert channel["Id"]["name"] == frame, (target, "frame order")
                assert channel["Id"]["path"] == f"sprites/{target}/{target}.yy"
    originals, variants = sprite_frames(source), sprite_frames(target)
    for frame, original, variant in zip(new["frames"], originals, variants, strict=True):
        assert original.size == variant.size, (target, "dimensions")
        assert equal_pixels(original.getchannel("A"), variant.getchannel("A")), (target, "alpha/mask geometry")
        for layer in new["layers"]:
            image = Image.open(PROJECT / "sprites" / target / "layers" / frame["name"] / (layer["name"] + ".png")).convert("RGBA")
            assert equal_pixels(image, variant), (target, "editable layer")
    return len(variants)


def main():
    """Fail if any theme resource breaks the source masks or level-art contract."""
    project = read_resource(PROJECT / "RandomForest.yyp")
    entries = {r["id"]["name"]: r["id"]["path"] for r in project["resources"]}
    assert len(entries) == len(project["resources"]), "duplicate project assets"
    count = 0
    for names in FAMILIES.values():
        for name in names:
            assert name + "Night" in entries
            count += audit_sprite(name, name + "Night")
            assert not (PROJECT / "sprites" / (name + "Evening")).exists()
            assert not (PROJECT / "sprites" / (name + "Morning")).exists()
    for name in ("tsPlatforms", "tsSpikes", "tsSpikesExt"):
        old = read_resource(PROJECT / "tilesets" / name / (name + ".yy"))
        target = name + "Night"
        new = read_resource(PROJECT / "tilesets" / target / (target + ".yy"))
        ignored = {"name", "%Name", "spriteId"}
        assert {k: v for k, v in old.items() if k not in ignored} == {
            k: v for k, v in new.items() if k not in ignored}, (target, "tile layout and autotiles")
        assert new["spriteId"]["name"] == old["spriteId"]["name"] + "Night"
        assert target in entries
        original_packed = Image.open(PROJECT / "tilesets" / name / "output_tileset.png").convert("RGBA")
        packed = Image.open(PROJECT / "tilesets" / target / "output_tileset.png").convert("RGBA")
        assert equal_pixels(original_packed.getchannel("A"), packed.getchannel("A")), (target, "packed tile alpha")
        expected = packed_tileset(new, sprite_frames(new["spriteId"]["name"])[0], original_packed)
        assert equal_pixels(packed, expected), (target, "runtime packed tile colors")
    for suffix in ("", "Evening", "Night", "Morning"):
        for postfix, size in (("", (480, 270)), ("_x13", (624, 351))):
            name = "sBackground" + suffix + postfix
            assert name in entries
            assert sprite_frames(name)[0].size == size
            audit_sprite("sBackground" + postfix, name)
    for postfix in ("", "_x13"):
        assert equal_pixels(sprite_frames("sBackground" + postfix)[0],
                            sprite_frames("sBackgroundMorning" + postfix)[0]), "morning day-copy"
    for name in ("oSkeleton", "oBungalo", "oSlimeBloom", "oSkeletonBloom", "oBungaloBloom"):
        obj = read_resource(PROJECT / "objects" / name / (name + ".yy"))
        assert any(e["eventType"] == 8 and e["eventNum"] == 0 for e in obj["eventList"])
    for entry in entries.values():
        assert (PROJECT / entry).is_file(), entry
    print(f"PASS: {count} night frames; all collision settings, alpha bytes, origins, animation timings, tile layouts and background resources.")


if __name__ == "__main__":
    main()
