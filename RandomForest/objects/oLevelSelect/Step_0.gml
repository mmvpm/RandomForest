// Returns the number of level buttons visible on the current page.
function __funVisibleLevelCount() {
	var first_level = self.page_index * self.page_size
	return min(self.page_size, self.levels_count - first_level)
}

// Advances a menu firefly and reflects it from the tile interior.
function __funUpdateLevelFirefly(firefly, extent) {
	funFireflyUpdate(firefly, self.level_firefly_speed)
	if (firefly.x < -extent) {
		firefly.x = -extent
		firefly.vx = abs(firefly.vx)
		firefly.target_vx = abs(firefly.target_vx)
	}
	else if (firefly.x > extent) {
		firefly.x = extent
		firefly.vx = -abs(firefly.vx)
		firefly.target_vx = -abs(firefly.target_vx)
	}
	if (firefly.y < -extent) {
		firefly.y = -extent
		firefly.vy = abs(firefly.vy)
		firefly.target_vy = abs(firefly.target_vy)
	}
	else if (firefly.y > extent) {
		firefly.y = extent
		firefly.vy = -abs(firefly.vy)
		firefly.target_vy = -abs(firefly.target_vy)
	}
}

// Returns whether one level or navigation button can be used.
function __funLevelButtonIsEnabled(button_index) {
	if (button_index >= 0 and button_index < __funVisibleLevelCount()) {
		var level_index = self.page_index * self.page_size + button_index
		return level_index <= global.current_level
	}
	if (button_index == self.previous_index) {
		return self.page_index > 0
	}
	if (button_index == self.next_index) {
		return self.page_index < self.page_count - 1
	}
	return button_index == self.exit_index
}

// Changes selection only to a visible and enabled button.
function __funSelectLevelButton(button_index) {
	if (
		__funLevelButtonIsEnabled(button_index)
		and button_index != self.current_index
	) {
		self.current_index = button_index
		audio_play_sound(soundMenuButton, 0, false)
	}
}

// Opens a page and selects its first unlocked level when possible.
function __funOpenLevelPage(page_index) {
	self.page_index = clamp(page_index, 0, self.page_count - 1)
	var first_level = self.page_index * self.page_size
	self.current_index = (
		first_level <= global.current_level
		? 0
		: self.previous_index
	)
	funMenuBackgroundSetTheme(funLevelTheme(first_level))
	audio_play_sound(soundMenuButton, 0, false)
}

// Opens a level or handles one of the navigation controls.
function __funActivateLevelButton(button_index) {
	if (!__funLevelButtonIsEnabled(button_index)) {
		return
	}
	if (button_index == self.previous_index) {
		__funOpenLevelPage(self.page_index - 1)
		return
	}
	if (button_index == self.next_index) {
		__funOpenLevelPage(self.page_index + 1)
		return
	}
	if (button_index == self.exit_index) {
		global.menu_background_handoff = true
		global.skip_menu_fade_once = true
		room_goto(rMenu)
		return
	}

	var level_index = self.page_index * self.page_size + button_index
	funOpenLevel(level_index)
}

// Returns the first unlocked level button on the current page.
function __funFirstAvailableLevelButton() {
	return __funLevelButtonIsEnabled(0) ? 0 : -1
}

// Returns the last unlocked level button on the current page.
function __funLastAvailableLevelButton() {
	var first_level = self.page_index * self.page_size
	var last_visible = __funVisibleLevelCount() - 1
	var last_unlocked = global.current_level - first_level
	var button_index = min(last_visible, last_unlocked)
	return button_index >= 0 ? button_index : -1
}

// Returns an enabled control when the page contains no unlocked levels.
function __funLevelControlFallback() {
	if (
		self.current_index != self.previous_index
		and __funLevelButtonIsEnabled(self.previous_index)
	) {
		return self.previous_index
	}
	if (
		self.current_index != self.next_index
		and __funLevelButtonIsEnabled(self.next_index)
	) {
		return self.next_index
	}
	if (self.current_index != self.exit_index) {
		return self.exit_index
	}
	return self.current_index
}

// Returns the requested level or an enabled navigation control.
function __funLevelOrFallback(button_index) {
	if (__funLevelButtonIsEnabled(button_index)) {
		return button_index
	}
	return __funLevelControlFallback()
}

// Enters the grid from the previous-page button.
function __funEnterLevelGridFromLeft() {
	var lower_left = self.columns_count
	if (__funLevelButtonIsEnabled(lower_left)) {
		return lower_left
	}
	return __funLevelOrFallback(__funFirstAvailableLevelButton())
}

// Enters the grid from the next-page button.
function __funEnterLevelGridFromRight() {
	var lower_right = self.page_size - 1
	if (__funLevelButtonIsEnabled(lower_right)) {
		return lower_right
	}
	return __funLevelOrFallback(__funLastAvailableLevelButton())
}

// Returns the closest unlocked button in the next grid row.
function __funLevelBelow() {
	var next_row_start = (
		(self.current_index div self.columns_count + 1)
		* self.columns_count
	)
	var last_available = __funLastAvailableLevelButton()
	if (next_row_start > last_available) {
		return self.exit_index
	}
	var column = self.current_index mod self.columns_count
	return min(next_row_start + column, last_available)
}

// Returns a lower-row level on the requested side of the exit button.
function __funExitSideLevel(direction_x) {
	var last_available = __funLastAvailableLevelButton()
	if (last_available < 0) {
		return __funLevelControlFallback()
	}
	var row_start = (last_available div self.columns_count) * self.columns_count
	var preferred_column = direction_x < 0 ? 1 : 3
	return min(row_start + preferred_column, last_available)
}

// Returns the closest upper or lower destination for a page button.
function __funPageButtonVertical(direction_y, from_left) {
	var last_available = __funLastAvailableLevelButton()
	if (last_available < 0) {
		return __funLevelControlFallback()
	}
	if (direction_y < 0) {
		var top_target = from_left ? 0 : min(self.columns_count - 1, last_available)
		return __funLevelOrFallback(top_target)
	}
	var bottom_row_start = (
		(last_available div self.columns_count)
		* self.columns_count
	)
	var bottom_target = from_left ? bottom_row_start : last_available
	return __funLevelOrFallback(bottom_target)
}

// Moves one grid selection without horizontal edge wrapping.
function __funMoveLevel(direction_x, direction_y) {
	var column = self.current_index mod self.columns_count
	if (direction_x < 0) {
		var left_index = self.current_index - 1
		if (column == 0) {
			left_index = (
				__funLevelButtonIsEnabled(self.previous_index)
				? self.previous_index
				: self.current_index
			)
		}
		__funSelectLevelButton(left_index)
		return
	}
	if (direction_x > 0) {
		var right_index = self.current_index + 1
		if (
			column == self.columns_count - 1
			or !__funLevelButtonIsEnabled(right_index)
		) {
			right_index = (
				__funLevelButtonIsEnabled(self.next_index)
				? self.next_index
				: self.current_index
			)
		}
		__funSelectLevelButton(right_index)
		return
	}
	if (direction_y < 0) {
		var upper_index = self.current_index - self.columns_count
		__funSelectLevelButton(
			upper_index >= 0 ? upper_index : self.exit_index
		)
		return
	}
	__funSelectLevelButton(__funLevelBelow())
}

// Applies page-aware keyboard navigation.
function __funMoveLevelSelection(direction_x, direction_y) {
	if (funIsSpecialLevelPage(self.page_index, self.page_size, self.levels_count)) {
		funMoveSpecialLevelSelection(direction_x, direction_y)
		return
	}
	if (self.current_index < self.page_size) {
		__funMoveLevel(direction_x, direction_y)
		return
	}
	if (self.current_index == self.previous_index) {
		var previous_target = self.current_index
		if (direction_x > 0) {
			previous_target = __funEnterLevelGridFromLeft()
		}
		else if (direction_y != 0) {
			previous_target = __funPageButtonVertical(direction_y, true)
		}
		__funSelectLevelButton(previous_target)
		return
	}
	if (self.current_index == self.next_index) {
		var next_target = self.current_index
		if (direction_x < 0) {
			next_target = __funEnterLevelGridFromRight()
		}
		else if (direction_y != 0) {
			next_target = __funPageButtonVertical(direction_y, false)
		}
		__funSelectLevelButton(next_target)
		return
	}
	if (direction_y < 0) {
		__funSelectLevelButton(
			__funLevelOrFallback(__funLastAvailableLevelButton())
		)
	}
	else if (direction_y > 0) {
		__funSelectLevelButton(
			__funLevelOrFallback(__funFirstAvailableLevelButton())
		)
	}
	else {
		__funSelectLevelButton(__funExitSideLevel(direction_x))
	}
}

// Ignore stationary mouse position briefly after entering the room.
if (self.mouse_allowed_counter != 0) {
	self.last_mouse_x = mouse_x - camera_get_view_x(view_camera[0])
	self.last_mouse_y = mouse_y - camera_get_view_y(view_camera[0])
}
self.mouse_allowed_counter = max(0, self.mouse_allowed_counter - 1)

// Only visible records need animation work; their local state survives paging.
var first_visible_level = self.page_index * self.page_size
var visible_level_count = __funVisibleLevelCount()
for (
	var visible_index = 0;
	visible_index < visible_level_count;
	++visible_index
) {
	var visible_level = first_visible_level + visible_index
	var tile_firefly = self.level_orange_fireflies[visible_level]
	if (tile_firefly != undefined) {
		__funUpdateLevelFirefly(
			tile_firefly,
			self.level_firefly_extent
		)
	}
}

// Start the one-time completion sweep when its page becomes visible.
if (
	self.completion_animation_counter < 0
	and global.pending_completed_page == self.page_index
) {
	self.completion_animation_counter = 0
	global.pending_completed_page = -1
}

// Enter or click skips the sweep without activating the selected control.
if (
	self.completion_animation_counter >= 0
	and (
		keyboard_check_pressed(vk_enter)
		or mouse_check_button_pressed(mb_left)
	)
) {
	self.completion_animation_counter = -1
	exit
}

if (self.completion_animation_counter >= 0) {
	++self.completion_animation_counter
	if (
		self.completion_animation_counter
		>= self.completion_animation_duration
	) {
		self.completion_animation_counter = -1
		audio_play_sound(soundStarCollecting, 0, false)
	}
}

if (keyboard_check_pressed(global.key_pause)) {
	__funActivateLevelButton(self.exit_index)
}
else if (keyboard_check_pressed(vk_enter)) {
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
	__funMoveLevelSelection(-1, 0)
}
else if (keyboard_check_pressed(vk_right)) {
	__funMoveLevelSelection(1, 0)
}
else if (keyboard_check_pressed(vk_up)) {
	__funMoveLevelSelection(0, -1)
}
else if (keyboard_check_pressed(vk_down)) {
	__funMoveLevelSelection(0, 1)
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

// Keep camera movement independent of the page's lighting transition.
funMenuBackgroundStep()
