/// Gives exploration its full duration after entry fade, then starts the monologue.
if (self.dialogue_finished and !self.portal_ready and !self.transform_running
	and keyboard_check_pressed(vk_space) and oPlayer.is_on_ground
	and !instance_exists(oPauseMenu)) {
	var target_dark = self.scene.transform == "dark"
	var started = false
	with (oPlayer) started = funPlayerBeginStoryTransform(target_dark,
		other.finish_transform, other.cancel_transform)
	self.transform_running = started
}
if (self.dialogue_started or self.exiting or instance_exists(oFadeIn)
	or keyboard_check_pressed(global.key_pause)) {
	exit
}
self.delay_frames = max(0, self.delay_frames - 1)
if (self.delay_frames > 0) {
	exit
}
self.dialogue_started = true
var dialogue = instance_create_layer(0, 0, "UI", oDialogue)

with (dialogue) {
	funBeginDialogue(other.lines, other.context.progress,
		funBlackRoomSetting(other.scene, "characters_per_second"),
		other.finish_dialogue)
}
