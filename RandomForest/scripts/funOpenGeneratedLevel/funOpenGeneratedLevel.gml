/// Loads and opens one bundled generated level by absolute level index.
function funOpenGeneratedLevel(level_index) {
	var catalog = funLoadChallengeCatalog()
	var generated_index = level_index - CAMPAIGN_LEVELS_COUNT
	var generated_count = array_length(catalog.levels)
	if (generated_index < 0 or generated_index >= generated_count) {
		return false
	}

	var level_data = funGenerateLevel({
		level_path: catalog.levels[generated_index]
	})
	var validation = funValidateGeneratedLevel(level_data)
	if (!validation.is_valid) {
		show_debug_message(validation.error)
		return false
	}

	global.playing_level = level_index
	global.playing_level_star_times = level_data.star_times
	global.generated_level_data = level_data
	global.last_completion_result = undefined
	audio_stop_sound(musicMenu)
	if (!audio_is_playing(musicGame)) {
		audio_play_sound(musicGame, 0, true)
	}
	if (room == rGeneratedLevel) {
		room_restart()
	}
	else {
		room_goto(rGeneratedLevel)
	}
	return true
}
