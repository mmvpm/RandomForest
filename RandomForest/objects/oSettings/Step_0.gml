/// Closes settings and restores normal menu hover handling.
function __funCloseSettings() {
	if (instance_exists(oMenu)) {
		oMenu.mouse_allowed_counter = 10
	}
	instance_destroy()
}

/// Toggles one settings row or closes the screen.
function __funActivateSetting(item_index) {
	switch (item_index) {
		case 0:
			funSetMusicEnabled(!global.music_enabled)
			audio_play_sound(soundMenuButton, 0, false)
			break
		case 1:
			if (global.sfx_enabled) {
				audio_play_sound(soundMenuButton, 0, false)
				funSetSfxEnabled(false)
			}
			else {
				funSetSfxEnabled(true)
				audio_play_sound(soundMenuButton, 0, false)
			}
			break
		case 2:
			__funCloseSettings()
			break
	}
}

/// Moves selection within the three settings rows.
function __funMoveSetting(direction) {
	self.current_index += direction
	self.current_index = (
		self.current_index + self.items_count
	) mod self.items_count
	audio_play_sound(soundMenuButton, 0, false)
}

self.mouse_allowed_counter = max(0, self.mouse_allowed_counter - 1)

if (keyboard_check_pressed(global.key_pause)) {
	__funCloseSettings()
}
else if (keyboard_check_pressed(vk_enter)) {
	__funActivateSetting(self.current_index)
}
else if (
	(self.current_index < 2)
	and (
		keyboard_check_pressed(vk_left)
		or keyboard_check_pressed(vk_right)
	)
) {
	__funActivateSetting(self.current_index)
}
else if (keyboard_check_pressed(vk_down)) {
	__funMoveSetting(1)
}
else if (keyboard_check_pressed(vk_up)) {
	__funMoveSetting(-1)
}
else if (mouse_check_button_pressed(mb_left)) {
	var clicked_index = funGetButtonByMouse(
		self.x_left_cached,
		self.x_right_cached,
		self.y_top_cached,
		self.y_bottom_cached,
		0,
		0,
		view_camera[0],
		false
	)
	if (clicked_index != -1) {
		self.current_index = clicked_index
		__funActivateSetting(clicked_index)
	}
}
else if (self.mouse_allowed_counter == 0) {
	var hovered_index = funGetButtonByMouse(
		self.x_left_cached,
		self.x_right_cached,
		self.y_top_cached,
		self.y_bottom_cached,
		0,
		0,
		view_camera[0],
		true
	)
	if (hovered_index != -1 and hovered_index != self.current_index) {
		self.current_index = hovered_index
		audio_play_sound(soundMenuButton, 0, false)
	}
}
