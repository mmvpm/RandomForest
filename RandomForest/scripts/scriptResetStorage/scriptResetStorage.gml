// debug functions

/// Restores general progress and audio preferences to defaults.
function funResetGeneral() {
	funResetBlackRoomScenes()
	global.is_fullscreen = false
	global.current_level = 0
	global.playing_level = 0
	global.playing_level_star_times = undefined
	global.is_training_completed = false
	global.is_game_finished = false
	global.hit_vs_tap_text_shown = 0
	global.music_enabled = true
	global.sfx_enabled = true

	funApplyAudioSettings()
	funSaveGameState()
}

/// Locks the level sequence back to its first level.
function funResetLevels() {
	funResetBlackRoomScenes()
	global.current_level = 0
	global.playing_level = 0
	global.playing_level_star_times = undefined
	global.is_training_completed = false
	global.is_game_finished = false

	funSaveGameState()
}

/// Clears time and achievement records for every level.
function funResetRecords() {
	for (var i = 0; i < array_length(global.time_records); ++i) {
		global.time_records[i] = -1
		global.enemy_clear_records[i] = false
		global.flawless_records[i] = false
		global.orange_firefly_records[i] = false
	}

	funSaveGameState()
}
