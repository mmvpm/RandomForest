"""Audit active themed draw paths and deliberate semantic-colour exceptions."""

import re
import subprocess

from theme_assets import PROJECT, ROOT, read_resource


def main():
    """Fail on uncovered green artwork, hardcoded green UI or changed original sprites."""
    effects = ("oTeleportStart", "oTeleportEnd", "oAirBack", "oAirBurst", "oTapDestroy", "oSwordBloom", "oPlayerBloom")
    for name in effects:
        assert "funDrawThemeEffectSelf()" in (PROJECT / "objects" / name / "Draw_0.gml").read_text(), name
        obj = read_resource(PROJECT / "objects" / name / (name + ".yy"))
        assert sum(e["eventType"] == 8 and e["eventNum"] == 0 for e in obj["eventList"]) == 1, name
    assert "funDrawThemedSelf()" in (PROJECT / "objects/oPointer/Draw_0.gml").read_text()
    for name in ("oMenu", "oLevelSelect", "oSettings", "oPauseMenu", "oLevelPassing"):
        draw = (PROJECT / "objects" / name / "Draw_64.gml").read_text()
        assert "funDrawUiPanel(" in draw, name
        assert "self.theme_presentation" in draw, name
    for path in (PROJECT / "objects").rglob("*.gml"):
        assert not re.search(r"make_colou?r_rgb\(\s*(112,\s*211,\s*112|58,\s*110,\s*58|125,\s*211,\s*189)\s*\)", path.read_text()), path
    optional = {
        "oPlayerJumpEffect/Draw_0.gml": "funThemeSprite(sPlayerJumpEffect",
        "oPlayerLandingEffect/Draw_0.gml": "funThemeSprite(sPlayerLandingEffect",
        "oHealthBar/Draw_0.gml": "funThemeSprite(sHealthBar",
        "oCoinCollector/Draw_0.gml": "funDrawThemeEffectSelf",
        "oTapController/Draw_0.gml": "funThemeSprite(sTapArrow",
        "oTraining/Draw_64.gml": "funDrawUiSprite",
    }
    for path, expected in optional.items():
        assert expected in (PROJECT / "objects" / path).read_text(), path
    # All original non-background PNG and metadata stay byte-for-byte untouched.
    originals = set(subprocess.check_output(["git", "ls-tree", "-r", "--name-only", "HEAD", "RandomForest/sprites"], cwd=ROOT, text=True).splitlines())
    changed = subprocess.check_output(["git", "diff", "HEAD", "--name-only", "--", "RandomForest/sprites"], cwd=ROOT, text=True)
    assert all("/sBackground/" in path or "/sBackground_x13/" in path
               for path in changed.splitlines() if path in originals), changed
    print("PASS: UI, rewards, magic, movement, pointer and optional neutral sprites; no green UI literals; original sprites and semantic colours preserved.")


if __name__ == "__main__":
    main()
