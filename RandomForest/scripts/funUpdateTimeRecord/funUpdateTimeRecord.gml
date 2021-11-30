function funUpdateTimeRecord(new_time) {
	var room_index = 0
	switch (room_get_name(room)) {
		case "rLevel00":
			room_index = 0
			break
		case "rLevel01":
			room_index = 1
			break
	}

	if (global.time_records[room_index] == -1 or new_time < global.time_records[room_index]) {
		global.time_records[room_index] = new_time
	}

	funSaveGameState()
}