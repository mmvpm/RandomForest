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
self.border_width = 140
self.border_height = 35

self.text_scale = 20 / 24
self.default_font = font_add("glasstown.ttf", 24, true, false, 32, 128)
self.border_font = font_add("glasstown.ttf", 24, true, false, 32, 128)

self.separate_dist = 0.2
self.top_item = 0.3

self.current_index = 0

self.back_surf = noone

var room_index = funGetRoomIndex()

self.current_time = oTimeCounter.time_counter
self.best_time = global.time_records[room_index]

self.shown_stars = -1
self.star_animation_delay = 10
self.star_animation_time = 20
self.star_animation_counter = 0
self.max_stars = funGetStarCount(self.current_time)

self.stats_animation_time = 60
self.stats_animation_counter = self.stats_animation_time

self.alpha_animation_time = 25
self.alpha_animation_counter = self.alpha_animation_time

self.border_animation_time = 25
self.border_animation_counter = self.border_animation_time

self.border_surf = noone

instance_deactivate_all(true)
instance_activate_object(oDebug)
instance_activate_object(oFullscreen)

self.sounds_played = 0 // ACHTUNG!!!


// mouse handle
self.last_mouse_x = 0
self.last_mouse_y = 0
self.x_shift_cached = 0
self.y_shift_cached = 0
self.x_left_cached = []
self.y_top_cached = []
self.x_right_cached = []
self.y_bottom_cached = []