"""Build an isolated runtime-check project without changing the real save or catalog."""

import json
import argparse
import shutil
from pathlib import Path

import theme_assets
from theme_assets import ROOT, read_resource, write_resource


def main():
    """Copy the game, disable saving and add a self-terminating visual test controller."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--presentation", action="store_true", help="Test palette transitions, effects and isolated future variants")
    parser.add_argument("--lighting", action="store_true", help="Test approved evening/morning art and the actual night sword")
    parser.add_argument("--forest-enemies", action="store_true", help="Test new enemy battles, navigation and projectile interception")
    parser.add_argument("--forest-revision", action="store_true", help="Test physical hops, simple masks, ceiling wake and anticipatory combat")
    parser.add_argument("--forest-feedback", action="store_true", help="Run only the focused hurt, knockback, impact and bat-retreat checks")
    parser.add_argument("--forest-maw", action="store_true", help="Test flying sword contacts and the rooted plant's recovery/death sequences")
    parser.add_argument("--forest-baseline", action="store_true", help="Benchmark the saved pre-revision project with the same fixture")
    parser.add_argument("--work-dir", type=Path, default=ROOT / ".temp/theme_smoke",
                        help="Keep this run's fixture and screenshots in a separate directory")
    args = parser.parse_args()
    if args.forest_feedback or args.forest_maw:
        args.forest_revision = True
    if args.forest_revision or args.forest_baseline:
        args.forest_enemies = True
    if args.forest_enemies:
        args.forest_revision = True
    work = args.work_dir.resolve()
    project = work / "project"
    source = ROOT / ".temp/enemy_revision/before" if args.forest_baseline else ROOT / "RandomForest"
    shutil.copytree(source, project, dirs_exist_ok=True)
    # No game-state writes are permitted from this test copy.
    (project / "scripts/funSaveGameState/funSaveGameState.gml").write_text(
        "/// Disables real save writes in this isolated visual check.\nfunction funSaveGameState() {}\n")
    script = "scriptThemeSmoke"
    write_resource(project / "scripts" / script / (script + ".yy"), {
        "$GMScript": "v1", "%Name": script, "name": script, "isCompatibility": False,
        "isDnD": False, "parent": {"name": "Scripts", "path": "folders/Scripts.yy"},
        "resourceType": "GMScript", "resourceVersion": "2.0"})
    smoke_source = "forest_enemy_smoke.gml" if args.forest_enemies else "theme_smoke.gml"
    if args.forest_revision or args.forest_baseline:
        smoke_source = "forest_enemy_revision_smoke.gml"
    shutil.copyfile(ROOT / "tools" / smoke_source, project / "scripts" / script / (script + ".gml"))
    if args.forest_enemies:
        script_path = project / "scripts" / script / (script + ".gml")
        script_path.write_text(script_path.read_text() + "\n" + (ROOT / "tools/forest_enemy_audio_smoke.gml").read_text())
        script_path.write_text(script_path.read_text() + "\n" + (ROOT / "tools/forest_enemy_feedback_smoke.gml").read_text())
        if args.forest_maw:
            script_path.write_text(script_path.read_text() + "\n" + (ROOT / "tools/forest_enemy_maw_smoke.gml").read_text())
        audio_path = project / "scripts/scriptForestEnemyAudio/scriptForestEnemyAudio.gml"
        # Observe native playback in the fixture without production test hooks or fake audio.
        audio_path.write_text(audio_path.read_text().replace("audio_play_sound(", "funForestSmokePlaySound("))
        if args.forest_revision or args.forest_baseline:
            core = project / "scripts/scriptForestEnemyCore/scriptForestEnemyCore.gml"
            core.write_text(core.read_text().replace("function funForestEnemyStep()", "function funForestEnemyMeasuredStep()") +
                "\n/// Measures the isolated actors without production profiling hooks.\n"
                "function funForestEnemyStep() { var started=get_timer();funForestEnemyMeasuredStep();"
                "global.forest_cpu_us+=get_timer()-started }\n")
        # Deterministic battle input and pause handling belong only to the save-free fixture.
        (project / "scripts/funReadInputs/funReadInputs.gml").write_text(
            "/// Disables external input in the battle fixture.\nfunction funReadInputs() {\n"
            "self.key_move_left_pressed=false;self.key_move_right_pressed=false;"
            "self.key_stomp_pressed=false;self.key_attack_pressed=false;self.key_tap_attack_pressed=false\n}\n")
        (project / "objects/oPauseMenu/Step_0.gml").write_text(
            "/// Disables pause overlays in the battle fixture.\nself.paused=false\n")
    if args.presentation or args.lighting:
        script_path = project / "scripts" / script / (script + ".gml")
        script_path.write_text(script_path.read_text() + "\n" + (ROOT / "tools/theme_presentation_smoke.gml").read_text())
    if args.lighting:
        script_path.write_text(script_path.read_text() + "\n" + (ROOT / "tools/lighting_smoke.gml").read_text())
    name = "oThemeSmoke"
    obj = read_resource(project / "objects/oDebug/oDebug.yy")
    obj.update(name=name, persistent=True, visible=True, spriteId=None, spriteMaskId=None, parentObjectId=None)
    obj["%Name"] = name
    obj["eventList"] = [{"$GMEvent": "v1", "%Name": "", "collisionObjectId": None,
                         "eventNum": number, "eventType": kind, "isDnD": False, "name": "",
                         "resourceType": "GMEvent", "resourceVersion": "2.0"}
                        for kind, number in [(0, 0), (3, 0), (8, 75)]]
    write_resource(project / "objects" / name / (name + ".yy"), obj)
    step = "funMawSmokeStep" if args.forest_maw else "funLightingSmokeStep" if args.lighting else "funThemePresentationSmokeStep" if args.presentation else "funThemeSmokeStep"
    for event, method in [("Create_0", "funThemeSmokeCreate"), ("Step_0", step), ("Draw_75", "funThemeSmokeDraw")]:
        setup = "self.output_directory = " + json.dumps(str(work) + "/") + "\n" if event == "Create_0" else ""
        if event == "Create_0":
            setup += "global.forest_benchmark_only=" + ("true" if args.forest_baseline else "false") + "\n"
            setup += "global.forest_feedback_only=" + ("true" if args.forest_feedback else "false") + "\n"
        (project / "objects" / name / (event + ".gml")).write_text("/// Executes the isolated theme check.\n" + setup + method + "()\n")
    loading = project / "objects/oLoading/Create_0.gml"
    loading.write_text(loading.read_text() + "\ninstance_create_depth(0, 0, -10000, oThemeSmoke)\n")
    for event in ("oLevelPassing/Create_0.gml", "oPauseMenu/Step_0.gml"):
        path = project / "objects" / event
        path.write_text(path.read_text() + "\n// Keep the isolated test clock alive beneath overlays.\ninstance_activate_object(oThemeSmoke)\n")
    theme_assets.PROJECT = project
    resources = [("scripts", script), ("objects", name)]
    if args.presentation:
        # Test-only siblings and catalog entries never touch production artwork or saves.
        for base in ("sStar", "sAirBurst", "sPointer"):
            for suffix in ("Evening", "Morning"):
                target = base + suffix
                if (project / f"sprites/{target}/{target}.yy").exists():
                    continue  # Never replace approved production art with a future-asset fixture.
                theme_assets.clone_sprite(base, target, theme_assets.sprite_frames(base + "Night"))
                resources.append(("sprites", target))
    if args.presentation or args.lighting:
        # Reveal the not-yet-authored final menu page in this isolated copy only.
        catalog_path = project / "datafiles/challenge_levels/catalog.json"
        catalog = read_resource(catalog_path)
        catalog["levels"] += [catalog["levels"][-1]] * (31 - len(catalog["levels"]))
        write_resource(catalog_path, catalog)
    theme_assets.register_resources(resources)
    options = read_resource(ROOT / ".temp/theme_build/compile.bff")
    options.update(projectDir=str(project), projectPath=str(project / "RandomForest.yyp"),
                   outputFolder=str(work / "output"), tempFolder=str(work), tempFolderUnmapped=str(work),
                   compile_output_file_name=str(work / "output/game.zip"))
    write_resource(work / "compile.bff", options)
    print(f"Isolated visual test: {project}")


if __name__ == "__main__":
    main()
