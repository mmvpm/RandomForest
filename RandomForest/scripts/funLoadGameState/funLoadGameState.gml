function funLoadGameState() {
	ini_open("save.ini")

	// current level number
	var current_level_received = ini_read_real("general", "current_level", -1)
	if (current_level_received != -1) { // if value exists in the file
		global.current_level = current_level_received
	}

	// save time records
	var levels_count = array_length(global.time_records)
	for (var i = 0; i < levels_count; ++i) {
		var str_i = string(i) // "1"
		if (i < 10) {
			str_i = "0" + str_i // "01"
		}

		var time_record_received = ini_read_real("time_records", "level" + str_i, -1)
		if (time_record_received != -1) { // if value exists in the file
			global.time_records[i] = time_record_received
		}
	}

	ini_close()
}