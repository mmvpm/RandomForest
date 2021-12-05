function funLoadGameState() {
	ini_open("save.ini")

	// current level number
	global.current_level = ini_read_real("general", "current_level", 0) // default: 0-th level

	// is training completed
	global.is_training_completed = ini_read_real("general", "is_training_completed", 0) // false by default

	// is game finished
	global.is_game_finished = ini_read_real("general", "is_game_finished", 0) // false by default

	// save time records
	var levels_count = 2 // IMPORTANT
	for (var i = 0; i < levels_count; ++i) {
		var str_i = string(i) // "1"
		if (i < 10) {
			str_i = "0" + str_i // "01"
		}

		global.time_records[i] = ini_read_real("time_records", "level" + str_i, -1) // use -1 for default
	}

	ini_close()
}