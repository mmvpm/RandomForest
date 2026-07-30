// Load the complete level sequence and generated star metadata once.
var catalog = funLoadChallengeCatalog()
self.generated_paths = catalog.levels
self.levels_count = CAMPAIGN_LEVELS_COUNT + array_length(self.generated_paths)
self.level_star_times = array_create(self.levels_count, undefined)
for (
	var level_index = CAMPAIGN_LEVELS_COUNT;
	level_index < self.levels_count;
	++level_index
) {
	var generated_index = level_index - CAMPAIGN_LEVELS_COUNT
	var level_data = funGenerateLevel({
		level_path: self.generated_paths[generated_index]
	})
	self.level_star_times[level_index] = level_data.star_times
}

// Page and selection always follow the furthest unlocked level on entry.
self.columns_count = 5
self.page_size = LEVEL_SELECT_PAGE_SIZE
self.page_count = max(1, ceil(self.levels_count / self.page_size))
var selected_level = clamp(
	floor(global.current_level),
	0,
	self.levels_count - 1
)
self.page_index = selected_level div self.page_size
self.current_index = selected_level mod self.page_size
self.previous_index = self.page_size
self.exit_index = self.page_size + 1
self.next_index = self.page_size + 2
self.buttons_count = self.page_size + 3

// Button style shared with the main menu.
self.current_color = make_color_rgb(112, 211, 112) // light-green
self.default_color = c_ltgray
self.locked_color = c_dkgray
self.current_button_color = make_color_rgb(58, 110, 58) // dark-green
self.default_button_color = c_ltgray
self.locked_button_color = make_color_rgb(72, 72, 72)
self.current_scale = 1.0
self.default_scale = 0.9
self.border_sprite = sBorder4
self.level_button_size = 42
self.exit_button_width = 160
self.exit_button_height = 35
self.page_button_width = self.level_button_size / 2
self.page_button_height = 32
self.text_scale = 20 / 24

// Fixed layout for the 480 x 270 menu view.
self.grid_left = 144
self.grid_top = 112
self.grid_step_x = 48
self.grid_step_y = 48
self.page_button_gap = 6
self.previous_x = self.grid_left - self.grid_step_x - self.page_button_gap
self.next_x = (
	self.grid_left
	+ self.grid_step_x * self.columns_count
	+ self.page_button_gap
)
self.page_buttons_y = self.grid_top + self.grid_step_y / 2
self.exit_x = 240
self.exit_y = 224

// Button centers keep drawing and keyboard navigation aligned.
self.button_x = array_create(self.buttons_count, 0)
self.button_y = array_create(self.buttons_count, 0)
for (var button_index = 0; button_index < self.page_size; ++button_index) {
	self.button_x[button_index] = (
		self.grid_left
		+ self.grid_step_x * (button_index mod self.columns_count)
	)
	self.button_y[button_index] = (
		self.grid_top
		+ self.grid_step_y * (button_index div self.columns_count)
	)
}
self.button_x[self.previous_index] = self.previous_x
self.button_y[self.previous_index] = self.page_buttons_y
self.button_x[self.exit_index] = self.exit_x
self.button_y[self.exit_index] = self.exit_y
self.button_x[self.next_index] = self.next_x
self.button_y[self.next_index] = self.page_buttons_y

// Blurred moving background.
self.back_surf = noone
var cam = view_camera[0]
var cam_w = camera_get_view_width(cam)
var cam_h = camera_get_view_height(cam)
self.back_scale = 1.3
self.back_max_x = (self.back_scale - 1) * cam_w
self.back_max_y = (self.back_scale - 1) * cam_h
self.back_x = random_range(0, self.back_max_x)
self.back_y = random_range(0, self.back_max_y)
self.back_speed_x = 0.1 * (2 * irandom_range(0, 1) - 1)
self.back_speed_y = self.back_speed_x * cam_h / cam_w * (2 * irandom_range(0, 1) - 1)

// Mouse hit boxes are filled during Draw GUI.
self.mouse_allowed_counter = 10
self.last_mouse_x = 0
self.last_mouse_y = 0
self.x_shift_cached = 0
self.y_shift_cached = 0
self.x_left_cached = array_create(self.buttons_count, -1000)
self.y_top_cached = array_create(self.buttons_count, -1000)
self.x_right_cached = array_create(self.buttons_count, -1000)
self.y_bottom_cached = array_create(self.buttons_count, -1000)

// A newly perfected page uses one short, skippable border sweep.
self.completion_animation_counter = -1
self.completion_animation_duration = 42
