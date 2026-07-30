function funLoadGameState() {
	ini_open("save.ini")

	// debug mode
	global.is_debug = ini_read_real("general", "is_debug", 0) // default: false

	// fullscreen mode
	global.is_fullscreen = ini_read_real("general", "is_fullscreen", 0) // default: false

	// Load one record array for the full ordered level sequence.
	var levels_count = funGetLevelsCount()
	global.time_records = array_create(levels_count, -1)
	for (var i = 0; i < levels_count; ++i) {
		var str_i = string(i)
		if (i < 10) {
			str_i = "0" + str_i
		}
		global.time_records[i] = ini_read_real("time_records", "level" + str_i, -1)
	}

	// current_level is the furthest unlocked absolute level index.
	global.current_level = clamp(
		floor(ini_read_real("general", "current_level", 0)),
		0,
		levels_count - 1
	)
	// Completing a former final level unlocks one newly appended catalog level.
	if (
		global.current_level < levels_count - 1
		and global.time_records[global.current_level] != -1
	) {
		++global.current_level
	}
	global.playing_level = global.current_level
	global.playing_level_star_times = undefined

	// is training completed
	global.is_training_completed = ini_read_real("general", "is_training_completed", 0) // false by default

	// A saved victory becomes stale when new levels are appended.
	global.is_game_finished = (
		ini_read_real("general", "is_game_finished", 0)
		and global.time_records[levels_count - 1] != -1
	)

	// "hit is stronger than tap-attack" shown or not
	global.hit_vs_tap_text_shown = ini_read_real("general", "hit_vs_tap_text_shown", 0) // 0 by default

	ini_close()
}
