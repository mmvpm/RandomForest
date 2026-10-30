/// Owns exploration, dialogue interruptions and one-shot story actions.
self.context = global.black_room_context
if (self.context == undefined) {
    funRestartPlayingLevel()
    exit
}
self.scene = self.context.scene
// Bloom (200) stays behind terrain (150), while actors (100) stay in front.
instance_create_depth(0, 0, 150, oBlackRoomTerrain)
self.lines = funLoadBlackRoomLines(self.scene, self.context.progress)
self.delay_frames = round(60 * funBlackRoomSetting(self.scene, "exploration_seconds"))
self.dialogue_started = false
self.dialogue_finished = false
self.portal_ready = false
self.transform_running = false
self.awaiting_transform = false
self.space_guard = 0
self.exiting = false
self.next_line = 0
self.ending_action = ""
self.ending_frame = 0
self.is_ending = variable_struct_exists(self.scene, "kind")

/// Creates only the remaining conversation after a silent action beat.
self.show_dialogue = method(self, function() {
    if (instance_exists(oPlayer)) oPlayer.story_pending = true
    var remaining = []
    for (var i = self.next_line; i < array_length(self.lines); ++i) array_push(remaining, self.lines[i])
    self.dialogue_offset = self.next_line
    var dialogue = instance_create_layer(0, 0, "UI", oDialogue)
    with (dialogue) funBeginDialogue(remaining, other.context.progress,
        funBlackRoomSetting(other.scene, "characters_per_second"), other.finish_dialogue)
})

/// Releases ordinary play only after a full input grace period.
self.finish_dialogue = method(self, function() {
    self.dialogue_finished = true
    self.space_guard = 36
    if (self.is_ending) {
        funFinishStoryEnding()
        return
    }
    self.context.reward_staged = true
    with (oPlayer) funPlayerRefreshAbilities()
    oPlayer.story_pending = false
    self.portal_ready = true
})

/// Removes the panel between authored beats without consuming another Space press.
self.pause_dialogue = method(self, function(next_index, action) {
    self.next_line = self.dialogue_offset + next_index
    self.space_guard = 36
    if (action == "transform") self.awaiting_transform = true
    else {
        self.ending_action = action
        if (action == "portal_run") self.portal_ready = true
        self.ending_frame = 0
    }
})

/// Resumes the monologue after the accepted transformation has finished.
self.finish_transform = method(self, function() {
    self.context.current_dark = self.scene.transform == "dark"
    self.transform_running = false
    self.awaiting_transform = false
    self.space_guard = 36
    self.show_dialogue()
})

oPlayer.health = self.context.health
oPlayer.max_health = self.context.max_health
oPlayer.story_pending = self.is_ending
if (self.is_ending) funPrepareStoryEnding()
else if (self.scene.after_level == 3) {
    // This population illustrates memories; it must never write a gameplay record.
    instance_create_depth(0, 0, 250, oFireflyManager)
}

audio_stop_sound(musicMenu)
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
