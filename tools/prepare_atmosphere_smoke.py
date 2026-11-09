"""Prepare a save-free copy for native background-audio transitions."""
import argparse
import json
import re
import shutil
from pathlib import Path


def read_resource(path):
    """Read GameMaker's JSON with its optional trailing commas."""
    return json.loads(re.sub(r",\s*([}\]])", r"\1", path.read_text()))


def write_resource(path, value):
    """Write only resources in the isolated test project."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def main():
    """Add an automated driver while disabling all production save writes."""
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work-dir", type=Path, default=root / ".temp/ambient-interface-20261108/smoke")
    work = parser.parse_args().work_dir.resolve()
    project = work / "project"
    shutil.copytree(root / "RandomForest", project, dirs_exist_ok=True)
    save = project / "scripts/funSaveGameState/funSaveGameState.gml"
    save.write_text("/// Disables saving in this isolated audio check.\nfunction funSaveGameState() {}\n")
    script = "scriptAtmosphereSmoke"
    resource = read_resource(project / "scripts/scriptWeatherAudio/scriptWeatherAudio.yy")
    resource.update(name=script)
    resource["%Name"] = script
    write_resource(project / f"scripts/{script}/{script}.yy", resource)
    shutil.copyfile(root / "tools/atmosphere_scene_smoke.gml", project / f"scripts/{script}/{script}.gml")
    name = "oAtmosphereSmoke"
    resource = read_resource(project / "objects/oDebug/oDebug.yy")
    resource.update(name=name, persistent=True, spriteId=None, spriteMaskId=None, parentObjectId=None)
    resource["%Name"] = name
    resource["eventList"] = [{"$GMEvent": "v1", "%Name": "", "collisionObjectId": None,
                            "eventNum": 0, "eventType": kind, "isDnD": False,
                            "name": "", "resourceType": "GMEvent", "resourceVersion": "2.0"}
                           for kind in (0, 3)]
    write_resource(project / f"objects/{name}/{name}.yy", resource)
    for event, function in (("Create_0", "funAtmosphereSmokeCreate"), ("Step_0", "funAtmosphereSmokeStep")):
        (project / f"objects/{name}/{event}.gml").write_text(f"/// Runs the isolated audio check.\n{function}()\n")
    loading = project / "objects/oLoading/Create_0.gml"
    loading.write_text(loading.read_text() + f"\ninstance_create_depth(0, 0, -10000, {name})\n")
    for event in ("oLevelPassing/Create_0.gml", "oPauseMenu/Step_0.gml", "oCampaignIntro/Create_0.gml"):
        path = project / f"objects/{event}"
        path.write_text(path.read_text() + f"\ninstance_activate_object({name})\n")
    yyp = project / "RandomForest.yyp"
    resource = read_resource(yyp)
    resource["resources"] += [{"id": {"name": asset, "path": f"{kind}/{asset}/{asset}.yy"}}
                              for kind, asset in (("scripts", script), ("objects", name))]
    write_resource(yyp, resource)
    options = read_resource(root / ".temp/theme_build/compile.bff")
    options.update(projectDir=str(project), projectPath=str(yyp), outputFolder=str(work / "output"),
                   tempFolder=str(work), tempFolderUnmapped=str(work),
                   compile_output_file_name=str(work / "output/game.zip"))
    write_resource(work / "compile.bff", options)
    print(f"Save-free audio fixture: {work}")


if __name__ == "__main__":
    main()
