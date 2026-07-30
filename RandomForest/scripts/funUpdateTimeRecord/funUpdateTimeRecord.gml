/// Updates the best time for one absolute level index.
function funUpdateTimeRecord(new_time, level_index = global.playing_level) {
	if (global.time_records[level_index] == -1 or new_time < global.time_records[level_index]) {
		global.time_records[level_index] = new_time
	}
}
