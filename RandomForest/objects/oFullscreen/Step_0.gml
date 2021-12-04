if (keyboard_check_pressed(global.key_fullscreen)) {
	global.is_fullscreen = !global.is_fullscreen
	funSaveGameState()
	window_set_fullscreen(global.is_fullscreen)
}