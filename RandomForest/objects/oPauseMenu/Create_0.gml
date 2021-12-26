self.paused = false
self.screenshot = noone

self.items_count = 4
self.strings = [
	"Продолжить",
	"Начать заново",
	"Справка",
	"Выйти в меню",
]

self.current_color = make_color_rgb(112, 211, 112) // light-green
self.default_color = c_ltgray

self.current_button_color = make_color_rgb(58, 110, 58) // dark-green
self.default_button_color = c_ltgray

self.current_scale = 1.0
self.default_scale = 0.9

self.border_sprite = sBorder4
self.border_width = 130
self.border_height = 35

self.text_scale = 20 / 24

self.separate_dist = 45
self.top_item = 80

self.current_index = 0

self.deactivated_all = false

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
