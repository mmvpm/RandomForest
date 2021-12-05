function funUpdateFullscreen() {
	if (global.is_fullscreen) {
		window_set_fullscreen(true)
	}
	else {
		window_set_fullscreen(false)
		funResizeWindow()
	}
}