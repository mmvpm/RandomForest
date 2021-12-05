function funSaveGameState() {
	ini_open("save.ini")

	// debug mode
	if (global.is_debug != undefined) {
		ini_write_real("general", "is_debug", global.is_debug)
	}

	// fullscreen mode
	if (global.is_fullscreen != undefined) {
		ini_write_real("general", "is_fullscreen", global.is_fullscreen)
	}

	// current level number
	if (global.current_level != undefined) {
		ini_write_real("general", "current_level", global.current_level)
	}

	// training completed
	if (global.is_training_completed != undefined) {
		ini_write_real("general", "is_training_completed", global.is_training_completed)
	}

	// is game finished
	if (global.is_game_finished != undefined) {
		ini_write_real("general", "is_game_finished", global.is_game_finished)
	}

	// save time records
	if (global.time_records != undefined) {
		var levels_count = array_length(global.time_records)
		for (var i = 0; i < levels_count; ++i) {
			var str_i = string(i) // "1"
			if (i < 10) {
				str_i = "0" + str_i // "01"
			}

			ini_write_real("time_records", "level" + str_i, global.time_records[i])
		}
	}

	ini_close()
}