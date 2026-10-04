/// Owns scene timing and music; the player remains fully controllable.
self.context = global.black_room_context
if (self.context == undefined) {
	funRestartPlayingLevel()
	exit
}
self.scene = self.context.scene
self.lines = funLoadBlackRoomLines(self.scene, self.context.progress)
self.delay_frames = round(60 * funBlackRoomSetting(self.scene, "exploration_seconds"))
self.dialogue_started = false
self.dialogue_finished = false
self.exiting = false

/// A bound callback also reaches this instance while aiming deactivates the world.
self.finish_dialogue = method(self, function() {
	self.dialogue_finished = true
})

oPlayer.health = self.context.health
oPlayer.max_health = self.context.max_health

audio_stop_sound(musicGame)
var track = funBlackRoomSetting(self.scene, "music")
if (track != undefined) {
	var sound = asset_get_index(track)
	if (sound != -1) {
		audio_sound_gain(sound, global.music_enabled ? 1 : 0, 0)
		audio_play_sound(sound, 0, true)
	}
}

var fade = instance_create_depth(0, 0, -10, oFadeIn)
fade.alpha_step = 1 / (60 * funBlackRoomSetting(self.scene, "fade_seconds"))
