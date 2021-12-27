function funLoadGameState() {
	ini_open("save.ini")

	// debug mode
	global.is_debug = ini_read_real("general", "is_debug", 0) // default: false

	// fullscreen mode
	global.is_fullscreen = ini_read_real("general", "is_fullscreen", 0) // default: false

	// current level number
	global.current_level = ini_read_real("general", "current_level", 0) // default: 0-th level

	// is training completed
	global.is_training_completed = ini_read_real("general", "is_training_completed", 0) // false by default

	// is game finished
	global.is_game_finished = ini_read_real("general", "is_game_finished", 0) // false by default

	// "hit is stronger than tap-attack" shown or not
	global.hit_vs_tap_text_shown = ini_read_real("general", "hit_vs_tap_text_shown", 0) // 0 by default

	// save time records
	var levels_count = 4 // IMPORTANT
	for (var i = 0; i < levels_count; ++i) {
		var str_i = string(i) // "1"
		if (i < 10) {
			str_i = "0" + str_i // "01"
		}

		global.time_records[i] = ini_read_real("time_records", "level" + str_i, -1) // use -1 for default
	}

	ini_close()
}