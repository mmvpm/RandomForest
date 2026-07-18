// Level grid configuration.
self.levels_count = 10
self.columns_count = 5
self.exit_index = self.levels_count
self.current_index = clamp(floor(global.current_level), 0, self.levels_count - 1)

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
self.text_scale = 20 / 24

// Fixed layout for the 480 x 270 menu view.
self.grid_left = 144
self.grid_top = 112
self.grid_step = 48
self.exit_x = 240
self.exit_y = 224

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
self.x_left_cached = []
self.y_top_cached = []
self.x_right_cached = []
self.y_bottom_cached = []
