// Returns whether a level button can be selected.
function __funLevelIsUnlocked(button_index) {
	return button_index >= 0 and button_index < self.levels_count and button_index <= global.current_level
}

// Changes selection only to enabled levels or the exit button.
function __funSelectLevelButton(button_index) {
	var button_allowed = button_index == self.exit_index or __funLevelIsUnlocked(button_index)
	if (button_allowed and button_index != self.current_index) {
		self.current_index = button_index
		audio_play_sound(soundMenuButton, 0, false)
	}
}

// Opens a level or returns to the main menu immediately.
function __funActivateLevelButton(button_index) {
	if (button_index != self.exit_index and !__funLevelIsUnlocked(button_index)) {
		return
	}

	if (button_index == self.exit_index) {
		// Skip the main menu fade only for this immediate return.
		global.skip_menu_fade_once = true
		room_goto(rMenu)
	}
	else {
		funMenuGoPlay(button_index)
	}
}

// Ignore stationary mouse position briefly after entering the room.
if (self.mouse_allowed_counter != 0) {
	self.last_mouse_x = mouse_x - camera_get_view_x(view_camera[0])
	self.last_mouse_y = mouse_y - camera_get_view_y(view_camera[0])
}
self.mouse_allowed_counter = max(0, self.mouse_allowed_counter - 1)

if (keyboard_check_pressed(vk_enter)) {
	__funActivateLevelButton(self.current_index)
}
else if (mouse_check_button_pressed(mb_left)) {
	var clicked_index = funGetButtonByMouse(
		self.x_left_cached, self.x_right_cached,
		self.y_top_cached, self.y_bottom_cached,
		self.x_shift_cached, self.y_shift_cached,
		view_camera[0], false
	)
	if (clicked_index != -1) {
		__funActivateLevelButton(clicked_index)
	}
}
else if (keyboard_check_pressed(vk_left)) {
	if (self.current_index != self.exit_index) {
		var current_column = self.current_index mod self.columns_count
		if (current_column > 0) {
			__funSelectLevelButton(self.current_index - 1)
		}
	}
}
else if (keyboard_check_pressed(vk_right)) {
	if (self.current_index != self.exit_index) {
		var current_column = self.current_index mod self.columns_count
		if (current_column < self.columns_count - 1) {
			__funSelectLevelButton(self.current_index + 1)
		}
	}
}
else if (keyboard_check_pressed(vk_up)) {
	if (self.current_index == self.exit_index) {
		__funSelectLevelButton(clamp(floor(global.current_level), 0, self.levels_count - 1))
	}
	else {
		var upper_index = self.current_index - self.columns_count
		if (upper_index >= 0) {
			__funSelectLevelButton(upper_index)
		}
	}
}
else if (keyboard_check_pressed(vk_down)) {
	if (self.current_index != self.exit_index) {
		var lower_index = self.current_index + self.columns_count
		if (__funLevelIsUnlocked(lower_index)) {
			__funSelectLevelButton(lower_index)
		}
		else {
			__funSelectLevelButton(self.exit_index)
		}
	}
}
else if (self.mouse_allowed_counter == 0) {
	var hovered_index = funGetButtonByMouse(
		self.x_left_cached, self.x_right_cached,
		self.y_top_cached, self.y_bottom_cached,
		self.x_shift_cached, self.y_shift_cached,
		view_camera[0], true
	)
	if (hovered_index != -1) {
		__funSelectLevelButton(hovered_index)
	}
}

// Update the moving background.
var next_x = self.back_x + self.back_speed_x
self.back_x = clamp(next_x, 0, self.back_max_x)
if (next_x != self.back_x) {
	self.back_speed_x *= -1
}

var next_y = self.back_y + self.back_speed_y
self.back_y = clamp(next_y, 0, self.back_max_y)
if (next_y != self.back_y) {
	self.back_speed_y *= -1
}
