self.frame_counter += 1


// switch to debug mode
if ( keyboard_check_pressed(string_ord_at(self.debug_password, self.debug_current_index)) ) {
	self.debug_current_index += 1
}
if (self.debug_current_index > string_length(self.debug_password)) {
	global.is_debug = !global.is_debug
	self.debug_current_index = 1
	audio_play_sound(soundCoinCollecting, 0, false) // just because
	funSaveGameState()
}


// if production
if (!global.is_debug) {
	return
}

// settings
if (keyboard_check_pressed(ord("R"))) { // reset saved level number
	funResetGeneral()
}
if (keyboard_check_pressed(ord("T"))) { // reset saved time records
	funResetRecords()
}
if (keyboard_check_pressed(ord("N"))) { // to next level
	room_goto_next()
}
if (keyboard_check_pressed(ord("P"))) { // to previous level
	room_goto_previous()
}
if (keyboard_check_pressed(ord("Q"))) { // auto collect all coins
	oCoinCollector.coins_collected += instance_number(oCoin)
	instance_destroy(oCoin)
}

// messages
if (self.frame_counter % 60 == 0) { 
	show_debug_message("is_fullscreen: " + string(global.is_fullscreen))
	show_debug_message("current_level: " + string(global.current_level))
	show_debug_message("is_game_finished: " + string(global.is_game_finished))
	show_debug_message("is_training_completed: " + string(global.is_training_completed))
	for (var i = 0; i < 7; ++i) {
		show_debug_message("global.time_records[" + string(i) + "]: " + string(global.time_records[i]))
	}
	show_debug_message("\n")
}