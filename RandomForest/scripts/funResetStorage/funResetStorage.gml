// debug function 
function funResetStorage(reset_times = false) {
	global.current_level = 0
	global.is_training_completed = false
	global.is_game_finished = false

	if (reset_times) {
		for (var i = 0; i < array_length(global.time_records); ++i) {
			global.time_records[i] = -1
		}
	}

	funSaveGameState()
}