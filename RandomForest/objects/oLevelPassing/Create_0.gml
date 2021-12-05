self.items_count = 3
self.strings = [
	"Перейти дальше",
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
self.border_width = 135
self.border_height = 35

self.default_font = font_add("glasstown.ttf", 20, true, false, 32, 128)
self.border_font = font_add("glasstown.ttf", 28, true, false, 32, 128)

self.separate_dist = 0.2
self.top_item = 0.3

self.current_index = 0

self.back_surf = noone

var room_index = funGetRoomIndex()

self.current_time = oTimeCounter.time_counter
self.best_time = global.time_records[room_index]

self.alpha_animation_time = 30
self.alpha_animation_counter = self.alpha_animation_time

self.border_animation_time = 25
self.border_animation_counter = self.border_animation_time

self.border_surf = noone

instance_deactivate_all(true)
