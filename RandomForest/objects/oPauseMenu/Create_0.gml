self.paused = false
self.screenshot = -1

self.items_count = 3
self.strings = [
	"Продолжить",
	"Начать заново",
	"Выйти в меню",
]

self.current_color = make_color_rgb(112, 211, 112) // light-green
self.default_color = c_ltgray

self.current_button_color = make_color_rgb(58, 110, 58) // dark-green
self.default_button_color = c_ltgray

self.current_scale = 1.0
self.default_scale = 0.9

self.border_sprite = sBorder4
self.border_width = 120
self.border_height = 35

self.default_font = font_add("glasstown.ttf", 20, true, false, 32, 128)

self.separate_dist = 0.2
self.top_item = 0.3

self.current_index = 0
