function funUpdateTimeRecord(new_time) {
	var room_index = funGetRoomIndex()

	if (global.time_records[room_index] == -1 or new_time < global.time_records[room_index]) {
		global.time_records[room_index] = new_time
	}

	funSaveGameState()
}