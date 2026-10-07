/// Checks the real skin/state and selected rendering assets without changing either.
function __funLightingAssert(theme) {
    var suffix = theme == "evening" ? "Evening" : (theme == "morning" ? "Morning" : "Night")
    var terrain = tilemap_get_tileset(layer_tilemap_get_id(layer_get_id("Platforms")))
    if (terrain != asset_get_index("tsPlatforms" + suffix)) show_error("Wrong selected terrain", true)
    var dark = theme == "night"
    if (oPlayer.is_dark != dark) show_error("Campaign skin changed", true)
    var sprite_name = sprite_get_name(oPlayer.sprite_index)
    if (string_pos("Evening", sprite_name) or string_pos("Morning", sprite_name)) show_error("State sprite replaced", true)
    var drawn = funThemeSprite(oPlayer.sprite_index, funVisualEffectTheme())
    if (!dark and drawn != asset_get_index(sprite_name + suffix)) show_error("Selected body not resolved", true)
    if (dark and drawn != oPlayer.sprite_index) show_error("Existing dark body replaced", true)
    if (funThemeSprite(sSwordBloom, theme) != asset_get_index("sSwordBloom" + suffix)) show_error("Sword bloom missing", true)
    var fx = [sPlayerFxLight, sPlayerFxLightToDark, sPlayerFxDarkToLight,
        sTapArrow, sTapArrowDiag, sTapCountdown, sTapCountdownDiag]
    if (!dark) {
        for (var i = 0; i < array_length(fx); ++i) {
            if (funThemeSprite(fx[i], theme) != asset_get_index(sprite_get_name(fx[i]) + suffix)) {
                show_error("Transform or aiming art missing", true)
            }
        }
    }
}

/// Runs real menus, terrain, player, sword rotation and pause for all new lighting.
function funLightingSmokeStep() {
    if (variable_instance_exists(self, "return_to_menu") and self.return_to_menu) {
        self.return_to_menu = false
        instance_activate_all()
        with (oPauseMenu) { self.paused = false; instance_destroy() }
        room_goto(rMenu)
        self.frames = 0
        return;
    }
    self.frames += 1
    if (self.frames < 60) return;
    var themes = ["evening", "morning", "night"]
    var levels = [20, 40, 30]
    var index = self.stage div 9
    var phase = self.stage mod 9
    if (index >= 3) {
        show_debug_message("SELECTED_LIGHTING_SMOKE_PASS")
        game_end()
        return;
    }
    var theme = themes[index]
    var prefix = "L-" + theme + "-"
    switch (phase) {
        case 0:
            global.current_level = levels[index]
            with (oMenu) funMenuBackgroundSetTheme(theme)
            self.stage += 1; self.frames = 0
            break
        case 1:
            __funThemeSmokeCapture(prefix + "menu")
            break
        case 2:
            funMenuOpenLevelSelect()
            self.stage += 1; self.frames = 0
            break
        case 3:
            if (funUiScenePresentation().theme != theme) show_error("Wrong level-select lighting", true)
            __funThemeSmokeCapture(prefix + "levels")
            break
        case 4:
            if (theme == "morning") {
                // The final map is not in the production catalog yet; do not add one.
                global.playing_level = 40
                global.generated_level_data = funGenerateLevel({level_path: "challenge_levels/21.json"})
                global.playing_level_star_times = global.generated_level_data.star_times
                room_goto(rGeneratedLevel)
            } else funOpenLevel(levels[index])
            self.stage += 1; self.frames = 0
            break
        case 5:
            __funLightingAssert(theme)
            var sword = __funThemePresentationSword(48)
            sword.current_speed = 0
            sword.effect_created = true
            if (sword.sprite_index != (theme == "night" ? sPlayerDarkTapSword : sPlayerTapSword)) {
                show_error("Flying sword lost base mask/skin", true)
            }
            __funThemeSmokeCapture(prefix + "game-sword-right")
            break
        case 6:
            with (oPlayerTapSword) { self.image_angle = 45; self.current_angle = 45 }
            __funLightingAssert(theme)
            __funThemeSmokeCapture(prefix + "game-sword-diagonal")
            break
        case 7:
            keyboard_key_press(global.key_pause)
            self.stage += 1; self.frames = 0
            break
        case 8:
            keyboard_key_release(global.key_pause)
            __funThemeSmokeCapture(prefix + "pause")
            // Transition on the next Step, after Draw GUI saved the composed pause.
            self.return_to_menu = true
            break
    }
}
