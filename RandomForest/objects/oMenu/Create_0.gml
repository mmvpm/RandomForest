funLoadGameState()

if (global.is_game_finished) {
	self.items_count = 3
	self.strings = [
		"Начать заново",
		"Справка",
		"Выйти",
	]
	self.functions = [
		funMenuResetLevelsAndGo,
		funMenuShowControls,
		funMenuExit,
	]
}
else if (global.is_training_completed) {
	self.items_count = 4
	self.strings = [
		"Продолжить",
		"Начать заново",
		"Справка",
		"Выйти",
	]
	self.functions = [
		funMenuGoPlay,
		funMenuResetLevelsAndGo,
		funMenuShowControls,
		funMenuExit,
	]
}
else {
	self.items_count = 3
	self.strings = [
		"Начать играть",
		"Справка",
		"Выйти",
	]
	self.functions = [
		funMenuGoPlay,
		funMenuShowControls,
		funMenuExit,
	]
}

self.current_color = make_color_rgb(112, 211, 112) // light-green
self.default_color = c_ltgray

self.current_button_color = make_color_rgb(58, 110, 58) // dark-green
self.default_button_color = c_ltgray

self.current_scale = 1.0
self.default_scale = 0.9

self.border_sprite = sBorder4
self.border_width = 160
self.border_height = 35

self.text_scale = 20 / 24

if (self.items_count == 4) {
	self.separate_dist = 42
	self.top_item = 105
}
else {
	self.separate_dist = 45
	self.top_item = 105
}

self.current_index = 0

// background
self.back_surf = noone

// fade in
self.alpha_animation_time = 60
self.alpha_animation_counter = self.alpha_animation_time

// background pos
var cam = view_camera[0]
var cam_w = camera_get_view_width(cam)
var cam_h = camera_get_view_height(cam)

self.back_scale = 1.3
self.back_max_x = (self.back_scale - 1) * cam_w
self.back_max_y = (self.back_scale - 1) * cam_h
self.back_x = random_range(0, back_max_x)
self.back_y = random_range(0, back_max_y)
self.back_speed_x = 0.1 * (2 * irandom_range(0, 1) - 1)
self.back_speed_y = self.back_speed_x * cam_h / cam_w * (2 * irandom_range(0, 1) - 1)

// mouse handle
self.mouse_allowed_counter = 10 // frames
self.last_mouse_x = 0
self.last_mouse_y = 0
self.x_shift_cached = 0
self.y_shift_cached = 0
self.x_left_cached = []
self.y_top_cached = []
self.x_right_cached = []
self.y_bottom_cached = []
