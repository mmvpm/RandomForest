if (keyboard_check_pressed(ord("R"))) {
	funResetStorage()
}
if (keyboard_check_pressed(ord("T"))) {
	funResetStorage(false)
}

/*if (self.frame_counter % 60 == 0){ 
	show_debug_message(global.time_records[0])
	show_debug_message(global.time_records[1])
	show_debug_message("\n")
}*/

self.frame_counter += 1