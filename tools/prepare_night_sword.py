"""Prepare a save-disabled native renderer for exact horizontal night sword pixels."""

import json
import shutil
import subprocess
import sys

from PIL import Image

import theme_assets
from lighting_assets import bank_frames
from theme_assets import PROJECT, ROOT, read_resource, write_resource

WORK = ROOT / ".temp/night_sword"
COLORS = {(227, 225, 205): (6, 0, 17), (255, 215, 144): (9, 0, 26),
          (147, 145, 126): (147, 145, 126), (0, 0, 0): (0, 0, 0)}


def job(base, output, table):
    """Read source colours only; the native GPU writes the resulting PNG."""
    source = bank_frames(PROJECT, base)[0]
    with Image.open(source) as image:
        colors = sorted({p[:3] for p in image.convert("RGBA").get_flattened_data() if p[3]})
    return dict(input=str(source), output=str(WORK / output), colors=[[list(c), list(table(c))] for c in colors])


def main():
    """Create a two-frame native RGB bake without rotating or changing the sword alpha."""
    reference = ROOT / ".temp/Player/Bonus/sword_dark.png"
    with Image.open(reference) as image:
        palette = {p[:3] for p in image.convert("RGBA").get_flattened_data() if p[3]}
    assert set(COLORS.values()) <= palette
    assert (90, 0, 255) in palette
    subprocess.run([sys.executable, str(ROOT / "tools/prepare_theme_smoke.py"), "--work-dir", str(WORK)], check=True)
    project = WORK / "project"
    jobs = [job("sPlayerTapSword", "night-sword.png", COLORS.__getitem__),
            job("sSwordBloom", "night-sword-bloom.png", lambda color: (90, 0, 255))]
    meta = read_resource(project / "RandomForest.yyp")
    meta["IncludedFiles"].append({"$GMIncludedFile": "", "%Name": "night-sword.json", "CopyToMask": -1,
        "filePath": "datafiles", "name": "night-sword.json", "resourceType": "GMIncludedFile", "resourceVersion": "2.0"})
    write_resource(project / "RandomForest.yyp", meta)
    background = bank_frames(PROJECT, "sBackgroundNight_x13")[0]
    origins = {name: read_resource(PROJECT / f"sprites/{name}/{name}.yy")["sequence"] for name in ("sPlayerTapSword", "sSwordBloom")}
    data = dict(jobs=jobs, reference=str(reference), background=str(background), preview=str(WORK / "preview.png"),
        sword_origin=[origins["sPlayerTapSword"][k] for k in ("xorigin", "yorigin")],
        bloom_origin=[origins["sSwordBloom"][k] for k in ("xorigin", "yorigin")])
    (project / "datafiles/night-sword.json").write_text(json.dumps(data, separators=(",", ":")))
    write_resource(WORK / "palette.json", data)
    shader = read_resource(PROJECT / "shaders/shBlur/shBlur.yy")
    shader["name"] = shader["%Name"] = "shSwordColorBake"
    write_resource(project / "shaders/shSwordColorBake/shSwordColorBake.yy", shader)
    shutil.copyfile(PROJECT / "shaders/shBlur/shBlur.vsh", project / "shaders/shSwordColorBake/shSwordColorBake.vsh")
    shutil.copyfile(ROOT / "tools/night_sword_bake.fsh", project / "shaders/shSwordColorBake/shSwordColorBake.fsh")
    shutil.copyfile(ROOT / "tools/night_sword_bake.gml", project / "scripts/scriptThemeSmoke/scriptThemeSmoke.gml")
    obj_path = project / "objects/oThemeSmoke/oThemeSmoke.yy"
    obj = read_resource(obj_path)
    obj["eventList"] = [e for e in obj["eventList"] if e["eventType"] == 8]
    write_resource(obj_path, obj)
    (obj_path.parent / "Draw_75.gml").write_text("/// Bakes exact sword RGB and exits.\nfunNightSwordBake()\n")
    theme_assets.PROJECT = project
    theme_assets.register_resources([("shaders", "shSwordColorBake")])
    print("Prepared exact 18x5 sword mask and independent violet bloom; no image rotation/resampling")


if __name__ == "__main__":
    main()
