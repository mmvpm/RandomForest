if (keyboard_check_pressed(ord("R"))) {
	funResetGeneral()
}
if (keyboard_check_pressed(ord("T"))) {
	funResetRecords()
}

if (self.frame_counter % 60 == 0) { 
	show_debug_message("current_level: " + string(global.current_level))
	show_debug_message("is_game_finished: " + string(global.is_game_finished))
	show_debug_message("is_training_completed: " + string(global.is_training_completed))
	for (var i = 0; i < 2; ++i) {
		show_debug_message("global.time_records[" + string(i) + "]: " + string(global.time_records[i]))
	}
	show_debug_message("\n")
}

self.frame_counter += 1