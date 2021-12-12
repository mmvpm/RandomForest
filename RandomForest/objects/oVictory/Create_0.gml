// upload font
self.default_font_12 = font_add("glasstown.ttf", 12, true, false, 32, 128)
self.default_font_24 = font_add("glasstown.ttf", 24, true, false, 32, 128)

// texts
self.victory_text  = "Поздравляю, вы прошли игру"
self.continue_text = "Для продолжения нажмите любую клавишу"


// find center
self.room_center_x = room_width / 2
self.room_center_y = room_height / 2

// alpha settings
self.text_alpha = 0.5

self.text_continue_alpha_min = 0.1
self.text_continue_alpha_max = 0.6
self.text_continue_alpha_current = 0.5

// time
self.tick_counter = 0
self.goto_next_level = false