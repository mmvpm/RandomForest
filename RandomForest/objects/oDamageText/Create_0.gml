/// @description Configure the short floating damage animation.

self.text = "-1"
self.text_color = c_white
self.outline_color = make_color_rgb(8, 16, 20)
self.base_scale = 0.75
self.current_scale = self.base_scale * 0.75
self.current_alpha = 1

self.age = 0
self.life_time = 32
self.fade_start = 10
self.pop_end = 4
self.settle_end = 8
self.start_y = self.y
self.rise_distance = 12
