function __funHandleButtonAction3(button_index) { // `3` because of gms2 (you never know what...)
	switch (button_index) {
		case 0:
			__funGoPlay()
			break
		case 1:
			funResetLevels()
			__funGoPlay()
			break
		case 2:
			game_end()
			break
	}
}


function __funGoPlay() {
	if (global.is_training_completed) {
		switch (global.current_level) {
			case 0:
				room_goto(rLevel00)
				break
			case 1:
				room_goto(rLevel01)
				break
		}
	}
	else {
		room_goto(rTraining)
	}
}

if (keyboard_check_pressed(vk_enter)) {
	__funHandleButtonAction3(self.current_index)
}
else if (mouse_check_button_pressed(mb_left)) {
	var new_button_index = funGetButtonByMouse(
		self.x_left_cached, self.x_right_cached,
		self.y_top_cached, self.y_bottom_cached,
		self.x_shift_cached, self.y_shift_cached, 
		view_camera[0], false
	)
	if (new_button_index != -1) {
		__funHandleButtonAction3(new_button_index)
	}
}
else if (keyboard_check_pressed(vk_down)) {
	self.current_index += 1
	self.current_index %= self.items_count
	audio_play_sound(soundMenuButton, 0, false)
}
else if (keyboard_check_pressed(vk_up)) {
	self.current_index += (self.items_count - 1)
	self.current_index %= self.items_count
	audio_play_sound(soundMenuButton, 0, false)
}
else {
	var new_button_index = funGetButtonByMouse(
		self.x_left_cached, self.x_right_cached,
		self.y_top_cached, self.y_bottom_cached,
		self.x_shift_cached, self.y_shift_cached, 
		view_camera[0], true
	)
	if (new_button_index != -1 and self.current_index != new_button_index) {
		self.current_index = new_button_index
		audio_play_sound(soundMenuButton, 0, false)
	}
}

// counters

if (self.alpha_animation_counter > 0) {
	--self.alpha_animation_counter
}
