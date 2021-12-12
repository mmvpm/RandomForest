self.items_count = 3
self.strings = [
	"Играть",
	"Начать заново",
	"Выйти",
]

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
self.default_font = font_add("glasstown.ttf", 24, true, false, 32, 128)

self.separate_dist = 45
self.top_item = 80

self.current_index = 0

// background
self.back_surf = noone

// fade in
self.alpha_animation_time = 60
self.alpha_animation_counter = self.alpha_animation_time

// mouse handle
self.last_mouse_x = 0
self.last_mouse_y = 0
self.x_shift_cached = 0
self.y_shift_cached = 0
self.x_left_cached = []
self.y_top_cached = []
self.x_right_cached = []
self.y_bottom_cached = []
