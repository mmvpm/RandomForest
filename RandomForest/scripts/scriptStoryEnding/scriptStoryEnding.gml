/// Identifies the two fully directed scenes independently of gameplay level indices.
function funStoryEndingActive() {
    return global.black_room_context != undefined
        and variable_struct_exists(global.black_room_context.scene, "kind")
}

/// Opens the appropriate ending without changing records or erasing the campaign.
function funOpenStoryEnding(true_ending = false) {
    var scene = global.black_room_config.scenes[array_length(global.black_room_config.scenes) - 1]
    if (true_ending) {
        scene = {id: "true_ending", after_level: 41, kind: "true_ending",
            dialogue: "narrative/dialogues/true_ending.json", exploration_seconds: 0,
            reward: {}, transform: undefined}
    }
    global.black_room_context = {scene: scene, progress: funBlackRoomProgress(41),
        health: funCampaignAbilities().max_health, max_health: funCampaignAbilities().max_health,
        reward_staged: false, current_dark: false}
    room_goto(rBlackRoom)
}

/// Uses the same black room with a clear stage for the character's own movement.
function funPrepareStoryEnding() {
    self.stage_prepared = false
    self.portal_closing = false
    self.portal_closed = false
    oBlackRoomPortal.x = 420
    oBlackRoomPortal.y = 240
    oBlackRoomPortal.scale = 0
    oPlayer.x = 108
    oPlayer.y = 264
    if (self.scene.kind == "true_ending") {
        oCamera.following = noone
        // Destroying the actors also removes their bloom followers on the next step.
        instance_destroy(oBlackRoomPortal)
        instance_destroy(oPlayer)
    }
}

/// Clears interior platforms after every authored room instance has been created.
function funClearStoryEndingStage() {
    with (oSolid) {
        if (self.x >= 24 and self.x < 480 and self.y > 12 and self.y < 264) instance_destroy()
    }
    self.stage_prepared = true
}

/// Ends the prank instantly, then restores the complete menu after its reveal.
function funFinishStoryEnding() {
    if (self.scene.kind == "finale") {
        global.ending_stage = 1
        funSaveGameState()
        global.skip_menu_fade_once = true
        room_goto(rMenu)
        return
    }
    global.ending_stage = 2
    funSaveGameState()
    self.exiting = true
    var fade = instance_create_depth(0, 0, -10, oFadeOut)
    fade.hold_black_frame = true
    fade.end_function = function() { room_goto(rMenu) }
}

/// Resumes speech only when a directed movement has settled on the ground.
function funStoryEndingResume() {
    self.ending_action = ""
    self.ending_frame = 0
    self.show_dialogue()
}

/// Schedules two silent beats; all movement still uses normal player physics.
function funStoryEndingStep() {
    if (instance_exists(oFadeIn)) return;
    self.ending_frame++
    if (self.ending_action == "first_walk") {
        if (self.ending_frame >= 105 and oPlayer.is_on_ground) funStoryEndingResume()
        return
    }
    if (self.ending_action == "freedom" and self.ending_frame >= 270) {
        self.ending_action = "portal_run"
        self.portal_ready = true
        self.ending_frame = 0
    }
    if (self.ending_action == "portal_run" and oBlackRoomPortal.scale >= 1
        and oPlayer.x >= 412 and oPlayer.y < 252) {
        // The final leap enters a live portal, without invoking level completion.
        oPlayer.image_alpha = 0
        oPlayer.visible = false
        self.portal_closing = true
        self.ending_action = "portal_close"
        self.ending_frame = 0
        if (instance_exists(oPlayerTapSword)) funPlayerTapSwordDestroy(false)
    }
    if (self.ending_action == "portal_close" and self.portal_closed) funStoryEndingResume()
}

/// Supplies a small authored performance instead of reading external controls.
function funStoryEndingPlayerInputs() {
    self.key_move_left_pressed = false
    self.key_move_right_pressed = false
    self.key_attack_pressed = false
    self.key_tap_attack_pressed = false
    self.key_stomp_pressed = false
    self.jump_buffer_counter = 0
    self.fall_buffer_counter = 0
    var controller = oBlackRoomController
    var frame = controller.ending_frame
    switch (controller.ending_action) {
        case "first_walk":
            self.key_move_right_pressed = frame < 55
            if (frame == 25) self.jump_buffer_counter = self.jump_buffer_max
            break
        case "freedom":
            // A look back, a running jump, throw, teleport, then a return to the door.
            self.key_move_left_pressed = frame >= 12 and frame < 43
            self.key_move_right_pressed = frame >= 64 and frame < 100
            if (frame == 72 or frame == 178) self.jump_buffer_counter = self.jump_buffer_max
            if (frame == 91) {
                var sword = instance_create_depth(self.x, self.y - 12, self.depth - 1, oPlayerTapSword)
                sword.current_angle = 20
                sword.image_angle = 20
                sword.shift_of_player_y = 12
                self.has_sword = false
                audio_play_sound(soundPlayerTapAttack, 2, false)
            }
            if (frame == 110 and instance_exists(oPlayerTapSword)) {
                if (funPlayerTapToEmptyPlace()) funPlayerChangeState(player_states.teleport)
                funPlayerTapSwordDestroy(false)
            }
            self.key_move_left_pressed = self.key_move_left_pressed or (frame >= 156 and frame < 215)
            self.key_attack_pressed = frame == 236
            break
        case "portal_run":
            if (oBlackRoomPortal.scale >= 1) {
                self.key_move_right_pressed = self.x < 426
                if (self.x >= 370 and self.is_on_ground) self.jump_buffer_counter = self.jump_buffer_max
            }
            break
    }
}
