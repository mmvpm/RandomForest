/// Fails the isolated run with a named contract and preserves its runtime log.
function funPlotAssert(condition, label) {
    if (!condition) show_error("PLOT_SMOKE_FAIL: " + label, true)
}

/// Starts a fresh test campaign without modifying the real save.
function funThemeSmokeCreate() {
    self.stage = 0
    self.frames = 0
    self.scene_index = 0
    self.pending_shot = ""
    self.seen_transform = false
    global.ending_stage = 0
    global.special_level_completed = false
    global.lost_clones = 127
    global.is_debug = false
    global.music_enabled = false
    global.sfx_enabled = true
    global.current_level = 40
    global.is_training_completed = true
    global.orange_firefly_records = array_create(41, false)
    funResetBlackRoomScenes()
    global.lost_clones = 127
    funApplyAudioSettings()
}

/// Starts one authored scene with normal exploration, physics and portal behavior.
function funPlotSmokeOpenScene() {
    var scene = global.black_room_config.scenes[self.scene_index]
    global.playing_level = scene.after_level - 1
    global.orange_firefly_records = array_create(41, false)
    for (var i = 0; i < min(scene.after_level, 40); ++i) global.orange_firefly_records[i] = true
    global.last_completion_result = {current_time: 42, best_time: 42, stars_before: 0, stars_after: 2,
        enemy_clear_before: false, enemy_clear_after: false, flawless_before: false,
        flawless_after: false, new_enemy_clear: false, new_flawless: false}
    global.black_room_context = {scene: scene, progress: funBlackRoomProgress(scene.after_level),
        health: 2, max_health: funCampaignAbilities().max_health, reward_staged: false,
        current_dark: scene.after_level == 40}
    self.seen_transform = false
    self.frames = 0
    room_goto(rBlackRoom)
}

/// Drives real Space edges; user controls remain disabled only in this fixture.
function funPlotSmokeDialogue() {
    keyboard_key_release(vk_space)
    if (instance_exists(oDialogue) and self.frames mod 4 == 0) {
        with (oDialogue) self.revealed = array_length(self.pages[self.page_index].glyphs)
        if (string_pos("[orange]", oDialogue.lines[oDialogue.line_index].text) > 0)
            self.pending_shot = "dialogue-" + string(oBlackRoomController.scene.after_level)
        if (oBlackRoomController.scene.id == "true_ending" and oDialogue.line_index == 7)
            self.pending_shot = "true-ending"
        keyboard_key_press(vk_space)
    }
}

/// Covers weather boundaries, stomp bodies, every scene, both endings and replay.
function funThemeSmokeStep() {
    self.frames++
    if (self.frames > 2400) show_error("PLOT_SMOKE_TIMEOUT " + string(self.stage), true)
    switch (self.stage) {
        case 0:
            if (room != rMenu or self.frames < 30) return;
            funPlotAssert(!funStoryLevelCanEnter(40), "memory gate before scene 40")
            funOpenLevel(0)
            self.stage = 1
            self.frames = 0
            break
        case 1:
            if (self.frames < 100) return;
            funPlotAssert(oWeatherAudio.scene_gain == 1, "nature entrance reaches full envelope")
            self.weather_voice = oWeatherAudio.active.voice
            keyboard_key_press(global.key_pause)
            self.stage = 2
            self.frames = 0
            break
        case 2:
            keyboard_key_release(global.key_pause)
            if (self.frames < 20) return;
            funPlotAssert(oWeatherAudio.scene_gain == 1, "pause does not fade nature")
            funPlotAssert(oWeatherAudio.active.voice == self.weather_voice, "pause keeps stream position")
            keyboard_key_press(global.key_pause)
            self.stage = 3
            self.frames = 0
            break
        case 3:
            keyboard_key_release(global.key_pause)
            if (self.frames < 10) return;
            var manager = oFireflyManager
            manager.fireflies = []
            for (var i = 0; i < 4; ++i) {
                var fly = funFireflyCreate(0, 0, 1, 1, true, i == 1, 0)
                fly.x = 120 + i * 40
                fly.y = 240
                fly.vx = 0
                fly.vy = 0
                fly.target_vx = 0
                fly.target_vy = 0
                fly.drift_strength = 0
                fly.target_timer = 999
                array_push(manager.fireflies, fly)
            }
            var wave = instance_create_depth(120, 240, 99, oPlayerStompWave)
            wave.max_radius = 84
            self.stage = 4
            self.frames = 0
            break
        case 4:
            if (self.frames < 42) return;
            funPlotAssert(global.orange_firefly_records[0], "stomp collects orange body")
            funPlotAssert(!oFireflyManager.fireflies[0].is_orange, "ordinary death removed before orange")
            room_goto(rMenu)
            self.stage = 5
            self.frames = 0
            break
        case 5:
            if (self.frames < 5) return;
            funPlotAssert(oWeatherAudio.live_streams == 0, "main menu stays silent without reviving nature")
            self.stage = 6
            funPlotSmokeOpenScene()
            break
        case 6:
            if (instance_exists(oLevelPassing)) {
                var scene = global.black_room_config.scenes[self.scene_index]
                funPlotAssert(variable_struct_get(global.black_room_seen, scene.id), "portal commits scene " + scene.id)
                show_debug_message("PLOT_SCENE_PASS " + scene.id)
                keyboard_key_release(global.key_move_left)
                keyboard_key_release(vk_space)
                instance_activate_all()
                self.scene_index++
                if (self.scene_index < array_length(global.black_room_config.scenes) - 1) funPlotSmokeOpenScene()
                else {
                    global.orange_firefly_records[0] = false
                    funPlotAssert(funStoryLevelUnlocked(40) and !funStoryLevelCanEnter(40), "00 looks enabled at 39/40")
                    funPlotAssert(!funOpenLevel(40), "direct final level gate")
                    funMenuOpenLevelSelect()
                    self.stage = 12
                    self.frames = 0
                }
                return
            }
            var controller = oBlackRoomController
            funPlotAssert(oPlayer.state != player_states.stomp, "Space does not spill into stomp")
            if (controller.scene.after_level == 3 and self.frames == 30) {
                funPlotAssert(instance_exists(oFireflyManager) and oFireflyManager.orange_firefly_active,
                    "scene 03 has both firefly colors")
                self.pending_shot = "scene03-fireflies"
            }
            if (controller.scene.after_level != 3) funPlotAssert(!instance_exists(oFireflyManager), "no other story fireflies")
            if (controller.awaiting_transform) {
                keyboard_key_release(vk_space)
                if (controller.space_guard > 0) funPlotAssert(!controller.transform_running, "36-frame transform input guard")
                if (controller.space_guard == 0 and !controller.transform_running and self.frames mod 4 == 0) keyboard_key_press(vk_space)
                self.seen_transform = self.seen_transform or controller.transform_running
            }
            else if (controller.dialogue_finished and controller.portal_ready and !controller.exiting) {
                if (controller.scene.transform != undefined) funPlotAssert(self.seen_transform, "required transform ran")
                keyboard_key_press(global.key_move_left)
            }
            else funPlotSmokeDialogue()
            break
        case 7:
            if (room == rMenu) {
                funPlotAssert(global.ending_stage == 1, "first ending saved")
                funPlotAssert(oMenu.items_count == 3 and oMenu.strings[0] == "Справка", "prank menu")
                self.pending_shot = "ending-menu"
                self.stage = 8
                self.frames = 0
                return
            }
            funPlotSmokeDialogue()
            if (oBlackRoomController.ending_action == "freedom" and oBlackRoomController.ending_frame == 100)
                self.pending_shot = "ending-throw"
            if (oBlackRoomController.ending_action == "portal_run" and oBlackRoomController.ending_frame == 45)
                self.pending_shot = "ending-portal"
            if (self.frames mod 60 == 0) show_debug_message("PLOT_ENDING "
                + oBlackRoomController.ending_action + " " + string(oBlackRoomController.ending_frame)
                + " player=" + string(oPlayer.x) + "," + string(oPlayer.y) + " state=" + string(oPlayer.state))
            break
        case 8:
            if (self.frames < 40) return;
            // Use the real Exit callback after its normal menu fade.
            var fade = instance_create_depth(0, 0, -10, oFadeOut)
            fade.end_function = funMenuExit
            self.stage = 9
            self.frames = 0
            break
        case 9:
            if (room == rMenu and global.ending_stage == 2) {
                funPlotAssert(oMenu.items_count == 4, "full menu restored")
                funPlotAssert(funFindBlackRoomScene(0) == undefined, "no scenes after true ending")
                funOpenLevel(0)
                self.stage = 10
                self.frames = 0
                return
            }
            if (room == rBlackRoom) {
                funPlotAssert(!instance_exists(oPlayer) and !instance_exists(oBlackRoomPortal), "true ending has no actors")
                funPlotSmokeDialogue()
            }
            break
        case 10:
            if (self.frames < 90) return;
            funPlotAssert(!oFireflyManager.orange_firefly_active, "no orange firefly on replay")
            show_debug_message("PLOT_SMOKE_PASS")
            game_end()
            break
        case 11:
            if (room != rMenu or self.frames < 30) return;
            for (var i = 0; i < array_length(global.black_room_config.scenes) - 1; ++i)
                variable_struct_set(global.black_room_seen, global.black_room_config.scenes[i].id, true)
            global.orange_firefly_records = array_create(41, true)
            global.orange_firefly_records[40] = false
            funOpenStoryEnding()
            self.stage = 7
            self.frames = 0
            break
        case 12:
            if (self.frames == 30) keyboard_key_press(vk_enter)
            if (self.frames == 31) keyboard_key_release(vk_enter)
            if (self.frames == 35) {
                funPlotAssert(oLevelSelect.memory_gate_frames > 0, "00 click shows the memory gate")
                self.pending_shot = "level00-gate"
            }
            if (self.frames < 215) return;
            funPlotAssert(oLevelSelect.memory_gate_frames == 0, "gate message expires after three seconds")
            global.orange_firefly_records[0] = true
            funPlotAssert(funStoryLevelCanEnter(40), "00 opens at 40/40")
            funOpenStoryEnding()
            self.stage = 7
            self.frames = 0
            break
    }
}

/// Saves the fully composed frame beside the permanent test logs.
function funThemeSmokeDraw() {
    if (self.pending_shot == "") return;
    screen_save(self.output_directory + self.pending_shot + ".png")
    self.pending_shot = ""
}
