/// Advances active gameplay time and the Space release guard.
if (self.is_ending and !self.stage_prepared) funClearStoryEndingStage()
if (keyboard_check_pressed(global.key_pause)
    or (instance_exists(oPauseMenu) and oPauseMenu.paused) or self.exiting) exit
self.space_guard = max(0, self.space_guard - 1)
if (self.is_ending and self.ending_action != "") {
    funStoryEndingStep()
    exit
}
if (self.awaiting_transform and !self.transform_running and self.space_guard == 0
    and keyboard_check_pressed(vk_space) and oPlayer.is_on_ground) {
    var target_dark = self.scene.transform == "dark"
    var started = false
    with (oPlayer) started = funPlayerBeginStoryTransform(target_dark, other.finish_transform)
    self.transform_running = started
}
if (self.dialogue_started or instance_exists(oFadeIn)) exit
if (instance_exists(oPlayer) and oPlayer.state == player_states.stomp) exit
self.delay_frames = max(0, self.delay_frames - 1)
if (self.delay_frames > 0) exit
self.dialogue_started = true
self.show_dialogue()
