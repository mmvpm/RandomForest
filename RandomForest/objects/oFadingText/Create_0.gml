// input parameters
self.text = "Текст..."
self.text_size = 20
self.active_time = 60 // frames
self.fading_time = 60 // frames

// font
self.text_scale = self.text_size / 24
self.default_font_24 = font_add("glasstown.ttf", 24, true, false, 32, 128)

// alpha
self.text_alpha_max = 0.9
self.text_alpha_current = self.text_alpha_max

// time
self.tick_counter = 0