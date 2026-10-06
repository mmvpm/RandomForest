/// Runs visual theme checks in an isolated project with saving disabled.
function funThemeSmokeCreate() {
    self.stage = 0
    self.frames = 0
    self.pending_shot = ""
    global.current_level = 30
    global.is_training_completed = true
    global.time_records = array_create(41, 100000)
    global.enemy_clear_records = array_create(41, false)
    global.flawless_records = array_create(41, false)
    global.orange_firefly_records = array_create(41, false)
    var scenes = global.black_room_config.scenes
    for (var i = 0; i < array_length(scenes); ++i) {
        variable_struct_set(global.black_room_seen, scenes[i].id, true)
    }
}

/// Captures the current frame before advancing to another visual scenario.
function __funThemeSmokeCapture(name) {
    self.pending_shot = name
    self.frames = 0
    self.stage += 1
    show_debug_message("THEME_SMOKE_CAPTURE " + name)
}

/// Tests real room drawing, page handoffs and future morning support.
function funThemeSmokeStep() {
    self.frames += 1
    var wait_frames = self.stage == 19 or self.stage == 23 ? 240 : 90
    if (self.frames < wait_frames) return;
    switch (self.stage) {
        case 0:
            __funThemeSmokeCapture("01-main-night")
            break
        case 1:
            funMenuOpenLevelSelect()
            self.stage += 1
            self.frames = 0
            break
        case 2:
            __funThemeSmokeCapture("02-level-select-night")
            break
        case 3:
            with (oLevelSelect) {
                self.page_index = 2
                self.current_index = 0
                funMenuBackgroundSetTheme("evening")
            }
            self.stage += 1
            self.frames = 0
            break
        case 4:
            __funThemeSmokeCapture("03-level-select-evening")
            break
        case 5:
            global.menu_background_handoff = true
            global.skip_menu_fade_once = true
            room_goto(rMenu)
            self.stage += 1
            self.frames = 0
            break
        case 6:
            __funThemeSmokeCapture("04-menu-return-night")
            break
        case 7:
            funOpenLevel(30)
            self.stage += 1
            self.frames = 0
            break
        case 8:
            __funThemeSmokeCapture("05-game-night")
            break
        case 9:
            funOpenLevel(0)
            self.stage += 1
            self.frames = 0
            break
        case 10:
            __funThemeSmokeCapture("06-game-day")
            break
        case 11:
            funOpenLevel(20)
            self.stage += 1
            self.frames = 0
            break
        case 12:
            __funThemeSmokeCapture("07-game-evening")
            break
        case 13:
            // Use an existing map at the future final index; never extend the catalog.
            global.playing_level = 40
            global.generated_level_data = funGenerateLevel({level_path: "challenge_levels/21.json"})
            global.playing_level_star_times = global.generated_level_data.star_times
            room_restart()
            self.stage += 1
            self.frames = 0
            break
        case 14:
            __funThemeSmokeCapture("08-game-morning")
            break
        case 15:
            funOpenLevel(30)
            self.stage += 1
            self.frames = 0
            break
        case 16:
            if (tilemap_get_tileset(layer_tilemap_get_id(layer_get_id("Platforms"))) != tsPlatformsNight) {
                show_error("Night terrain does not use its themed tileset", true)
            }
            keyboard_key_press(global.key_pause)
            self.stage += 1
            self.frames = 0
            break
        case 17:
            keyboard_key_release(global.key_pause)
            __funThemeSmokeCapture("09-pause-night")
            break
        case 18:
            with (oPauseMenu) self.paused = false
            instance_activate_all()
            global.last_completion_result = {
                current_time: 42, best_time: 42, stars_before: 0, stars_after: 2,
                enemy_clear_before: false, enemy_clear_after: true,
                flawless_before: false, flawless_after: false,
                new_enemy_clear: true, new_flawless: false,
            }
            funShowCompletedLevel()
            self.stage += 1
            self.frames = 0
            break
        case 19:
            __funThemeSmokeCapture("10-results-night")
            break
        case 20:
            instance_activate_all()
            with (oLevelPassing) instance_destroy()
            var scene = global.black_room_config.scenes[7]
            global.black_room_context = {
                scene: scene, progress: funBlackRoomProgress(scene.after_level),
                health: 6, max_health: 6, reward_staged: false, current_dark: true,
            }
            room_goto(rBlackRoom)
            self.stage += 1
            self.frames = 0
            break
        case 21:
            __funThemeSmokeCapture("11-black-room")
            break
        case 22:
            funFinishBlackRoomScene()
            self.stage += 1
            self.frames = 0
            break
        case 23:
            __funThemeSmokeCapture("12-results-after-black-room")
            break
        case 24:
            show_debug_message("THEME_SMOKE_PASS")
            game_end()
            break
    }
}

/// Saves the fully composed UI frame into the test output directory.
function funThemeSmokeDraw() {
    if (self.pending_shot == "") return;
    screen_save(self.output_directory + self.pending_shot + ".png")
    self.pending_shot = ""
}
