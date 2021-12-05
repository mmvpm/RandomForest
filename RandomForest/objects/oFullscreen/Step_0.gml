// switch mode
if (keyboard_check_pressed(global.key_fullscreen)) {
	global.is_fullscreen = !global.is_fullscreen
	funSaveGameState()
}

// update state (+ for external changes)
if (window_get_fullscreen() != global.is_fullscreen) {
	funUpdateFullscreen()
	self.alarm_counter = self.alarm_counter_max // for centering
}

// beg the window to center (please...)
if (self.alarm_counter != 0) {
	self.alarm_counter -= 1
	window_center()
}