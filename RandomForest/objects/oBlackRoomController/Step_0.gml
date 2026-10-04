/// Gives exploration its full duration after entry fade, then starts the monologue.
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
