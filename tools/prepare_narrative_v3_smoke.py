"""Prepare the v3 story check in a persistent, save-free project copy."""
import argparse
import json
import subprocess
import sys
from pathlib import Path


def main():
    """Reuse the campaign smoke driver with v3 menu and speaker assertions."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ending-only', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    work = root / '.temp/narrative_v3/smoke'
    subprocess.run([sys.executable, str(root / 'tools/prepare_theme_smoke.py'),
                    '--work-dir', str(work)], check=True)
    driver = (root / 'tools/plot_smoke.gml').read_text()
    driver = driver.replace('self.frames < 215', 'self.frames < 335').replace('gate message expires after three seconds', 'gate message expires after the existing five-second fade')
    driver = driver.replace('oMenu.items_count == 3 and oMenu.strings[0] == "Справка"',
                            'oMenu.items_count == 4 and oMenu.strings[0] == "Продолжить"')
    driver = driver.replace('case 8:\n            if (self.frames < 40) return;', '''case 8:
            keyboard_key_release(vk_enter)
            if (self.frames == 8 or self.frames == 12 or self.frames == 16) keyboard_key_press(vk_enter)
            if (self.frames == 20) {
                funPlotAssert(oMenu.runtime_errors == 3, "error stack keeps repeated clicks")
                funPlotAssert(!audio_is_playing(musicMenu), "broken menu is silent")
                self.pending_shot = "runtime-errors"
            }
            if (self.frames == 25) {
                self.frozen_x = oMenu.menu_background.x
                self.frozen_y = oMenu.menu_background.y
                funMenuOpenSettings()
            }
            if (self.frames == 40) {
                funPlotAssert(oMenu.menu_background.x == self.frozen_x and oMenu.menu_background.y == self.frozen_y, "settings keeps frozen backdrop")
                with (oSettings) instance_destroy()
                window_set_fullscreen(false)
            }
            if (self.frames == 100) self.pending_shot = "runtime-errors-windowed"
            if (self.frames == 110) {
                with (oMenu) repeat (100) funBrokenMenuContinue()
            }
            if (self.frames == 115) self.pending_shot = "runtime-errors-overflow"
            if (self.frames < 130) return;''')
    driver = driver.replace('funPlotSmokeDialogue()\n            if (oBlackRoomController.ending_action', '''funPlotSmokeDialogue()
            if (instance_exists(oDialogue) and oDialogue.speaker == "Она") {
                funPlotAssert(!oBlackRoomController.portal_ready, "she speaks before the portal opens")
                self.pending_shot = "she-speaks"
            }
            if (oBlackRoomController.ending_action''', 1)
    driver = driver.replace('with (oDialogue) self.revealed = array_length(self.pages[self.page_index].glyphs)',
                            'with (oDialogue) { if (!variable_struct_exists(self.lines[self.line_index], "auto_finish")) self.revealed = array_length(self.pages[self.page_index].glyphs) }')
    driver = driver.replace('keyboard_key_press(vk_space)\n    }\n}',
        'if (!variable_struct_exists(oDialogue.lines[oDialogue.line_index], "auto_finish")) keyboard_key_press(vk_space)\n    }\n}',1)
    driver = driver.replace('var controller = oBlackRoomController', '''if (oBlackRoomController.scene.after_level == 3) {
                if (self.frames == 50) {
                    with (oFireflyManager) funMemoryAbsorptionBurst(oPlayer.x + 60, oPlayer.y - 40)
                }
                if (self.frames == 60) self.pending_shot = "memory-absorption"
            }
            var controller = oBlackRoomController''')
    if args.ending_only:
        driver = driver.replace('self.stage = 0', 'self.stage = 11', 1)
    (work / 'project/scripts/scriptThemeSmoke/scriptThemeSmoke.gml').write_text(driver)
    options = json.loads((root / '.temp/narrative_v3/compile.bff').read_text())
    options.update(projectDir=str(work / 'project'), projectPath=str(work / 'project/RandomForest.yyp'),
                   outputFolder=str(work / 'output'), tempFolder=str(work), tempFolderUnmapped=str(work),
                   compile_output_file_name=str(work / 'output/game.zip'))
    (work / 'compile.bff').write_text(json.dumps(options, indent=2))
    print(f'V3 runtime fixture: {work}; game-state writes disabled.')


if __name__ == '__main__':
    main()
