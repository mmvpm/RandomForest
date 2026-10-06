/// Creates frozen real effect instances for a readable night/future-art contact scene.
function __funThemePresentationEffects() {
    var objects = [oTeleportStart, oTeleportEnd, oAirBack, oAirBurst, oTapDestroy,
        oPlayerJumpEffect, oPlayerLandingEffect, oPointer]
    var cam = view_camera[0]
    for (var i = 0; i < array_length(objects); ++i) {
        var effect = instance_create_depth(camera_get_view_x(cam) + 90 + (i mod 4) * 90,
            camera_get_view_y(cam) + 105 + (i div 4) * 85, -9000, objects[i])
        effect.image_speed = 0
        effect.image_index = 0
    }
}

/// Creates the real thrown-sword object with the original player/sword alignment.
function __funThemePresentationSword(offset) {
    return instance_create_layer(oPlayer.x + offset, oPlayer.y - abs(oPlayer.sprite_height) / 2,
        "Instances", oPlayerTapSword, {current_angle: 0, image_angle: 0,
            shift_of_player_y: abs(oPlayer.sprite_height) / 2})
}

/// Removes frozen previews so later assertions can only observe real gameplay effects.
function __funThemePresentationClearEffects() {
    with (oTeleportStart) instance_destroy()
    with (oTeleportEnd) instance_destroy()
    with (oAirBack) instance_destroy()
    with (oAirBurst) instance_destroy()
    with (oTapDestroy) instance_destroy()
    with (oPlayerJumpEffect) instance_destroy()
    with (oPlayerLandingEffect) instance_destroy()
    with (oPointer) instance_destroy()
}

/// Exercises overlays, crossfade checkpoints, real magic and fixture-only future variants.
function funThemePresentationSmokeStep() {
    self.frames += 1
    var wait_frames = 90
    if (self.stage == 8 or self.stage == 9) wait_frames = 15
    else if (self.stage == 11) wait_frames = 10
    else if (self.stage == 22) wait_frames = 3
    if (self.stage == 23) {
        if (self.frames > 10 and instance_exists(oPlayerLandingEffect)) {
            __funThemeSmokeCapture("P17-real-landing-night")
        } else if (self.frames > 120) show_error("Landing effect was not reached", true)
        return;
    }
    if (self.frames < wait_frames) return;
    switch (self.stage) {
        case 0: __funThemeSmokeCapture("P01-menu-night"); break
        case 1:
            funMenuOpenSettings()
            self.stage += 1; self.frames = 0
            break
        case 2: __funThemeSmokeCapture("P02-settings-night"); break
        case 3:
            with (oSettings) instance_destroy()
            funMenuShowControls()
            self.stage += 1; self.frames = 0
            break
        case 4: __funThemeSmokeCapture("P03-controls-night"); break
        case 5:
            with (oTraining) instance_destroy()
            instance_activate_all()
            funMenuOpenLevelSelect()
            self.stage += 1; self.frames = 0
            break
        case 6: __funThemeSmokeCapture("P04-level-select-night"); break
        case 7:
            with (oLevelSelect) { self.page_index = 2; self.current_index = 0; funMenuBackgroundSetTheme("evening") }
            self.stage += 1; self.frames = 0
            self.pending_shot = "P05-fade-start"
            break
        case 8: __funThemeSmokeCapture("P06-fade-middle"); break
        case 9: __funThemeSmokeCapture("P07-fade-end"); break
        case 10:
            with (oLevelSelect) { self.page_index = 3; funMenuBackgroundSetTheme("night") }
            self.stage += 1; self.frames = 0
            break
        case 11:
            with (oLevelSelect) { self.page_index = 0; funMenuBackgroundSetTheme("day") }
            self.stage += 1; self.frames = 0
            self.pending_shot = "P08-interrupted-fade"
            break
        case 12: __funThemeSmokeCapture("P09-level-select-day"); break
        case 13:
            global.current_level = 40
            with (oLevelSelect) { self.page_index = 4; self.current_index = 0; funMenuBackgroundSetTheme("morning") }
            self.stage += 1; self.frames = 0
            break
        case 14:
            if (funThemeSprite(sStar, "morning") != sStarMorning) show_error("Morning UI sibling missing", true)
            __funThemeSmokeCapture("P10-future-morning-ui")
            break
        case 15:
            with (oLevelSelect) { self.page_index = 2; self.current_index = 0; funMenuBackgroundSetTheme("evening") }
            global.theme_palettes.evening.accent = make_color_rgb(211, 184, 232)
            self.stage += 1; self.frames = 0
            break
        case 16:
            if (funUiScenePresentation().palette.accent != make_color_rgb(211, 184, 232)) show_error("Future palette not applied", true)
            __funThemeSmokeCapture("P11-future-evening-ui")
            break
        case 17:
            funOpenLevel(30)
            self.stage += 1; self.frames = 0
            break
        case 18:
            __funThemePresentationEffects()
            __funThemeSmokeCapture("P12-effects-night")
            break
        case 19:
            __funThemePresentationClearEffects()
            var sword = __funThemePresentationSword(48)
            sword.current_speed = 0
            sword.effect_created = true
            funPlayerTapSwordDestroy()
            with (oAirBack) image_speed = 0
            with (oTapDestroy) image_speed = 0
            __funThemeSmokeCapture("P13-real-sword-recall-night")
            break
        case 20:
            var sword = __funThemePresentationSword(0)
            sword.current_speed = 0
            sword.effect_created = true
            var success = false
            with (oPlayer) {
                success = funPlayerTapToEmptyPlace()
                if (success) {
                    funPlayerTeleportStart()
                    teleport_start_effect.image_index = 4
                    teleport_start_effect.image_speed = 0
                    funPlayerTeleportLogic()
                    teleport_end_effect.image_speed = 0
                    funPlayerTeleportEnd()
                }
            }
            if (!success) show_error("Real teleport did not find a safe position", true)
            funPlayerTapSwordDestroy(false)
            __funThemeSmokeCapture("P14-real-teleport-night")
            break
        case 21:
            keyboard_key_press(global.key_jump)
            self.stage += 1; self.frames = 0
            break
        case 22:
            keyboard_key_release(global.key_jump)
            if (!instance_exists(oPlayerJumpEffect)) show_error("Jump effect was not created", true)
            __funThemeSmokeCapture("P16-real-jump-night")
            break
        case 24:
            funOpenLevel(20)
            self.stage += 1; self.frames = 0
            break
        case 25:
            if (funThemeSprite(sAirBurst, "evening") != sAirBurstEvening) show_error("Evening effect sibling missing", true)
            __funThemePresentationEffects()
            __funThemeSmokeCapture("P18-future-evening-effects")
            break
        case 26:
            funOpenLevel(40)
            self.stage += 1; self.frames = 0
            break
        case 27:
            if (funVisualEffectTheme() != "morning" or funThemeSprite(sAirBurst, "morning") != sAirBurstMorning) {
                show_error("Morning effect sibling missing", true)
            }
            __funThemePresentationEffects()
            __funThemeSmokeCapture("P19-future-morning-effects")
            break
        case 28:
            show_debug_message("THEME_PRESENTATION_SMOKE_PASS")
            game_end()
            break
    }
}
