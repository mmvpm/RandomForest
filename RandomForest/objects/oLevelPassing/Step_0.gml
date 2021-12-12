function __funHandleButtonAction2(button_index) { // `2` because of gms2 (you never know what...)
	var chosen_function = undefined
	switch (button_index) {
		case 0:
			chosen_function = room_goto_next
			break
		case 1:
			chosen_function = room_restart
			break
		case 2:
			function __temp() { room_goto(rMenu) }
			chosen_function = __temp
			break
	}
	if (chosen_function != undefined) {
		var fade_out_effect = instance_create_depth(0, 0, -10, oFadeOut)
		fade_out_effect.end_function = chosen_function
	}
}


if (keyboard_check_pressed(vk_enter)) {
	__funHandleButtonAction2(self.current_index)
}
else if (mouse_check_button_pressed(mb_left)) {
	var new_button_index = funGetButtonByMouse(
		self.x_left_cached, self.x_right_cached,
		self.y_top_cached, self.y_bottom_cached,
		self.x_shift_cached, self.y_shift_cached, 
		view_camera[0], false
	)
	if (new_button_index != -1) {
		__funHandleButtonAction2(new_button_index)
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

if (self.border_animation_counter > 0) {
	--self.border_animation_counter
}

if (self.stats_animation_counter > 0) {
	--self.stats_animation_counter
}

if (self.star_animation_counter > 0) {
	--self.star_animation_counter
	if (self.star_animation_counter == 0) {
		++self.shown_stars
		if (self.sounds_played < self.max_stars) { // ACHTUNG!!!
			audio_play_sound(soundStarCollecting, 0, false)
			self.sounds_played += 1
		}
		self.star_animation_counter = self.star_animation_time + self.star_animation_delay
	}
}
