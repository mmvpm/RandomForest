// upload font
self.default_font_12 = font_add("glasstown.ttf", 12, true, false, 32, 128)
self.default_font_20 = font_add("glasstown.ttf", 20, true, false, 32, 128)

// texts
self.arrow_keys_text = "    -   Движение персонажа"
self.x_key_text      = "    -   Атака / Возврат меча"
self.c_key_text      = "    -   Бросок меча / Телепорт"
self.continue_text   = "Для продолжения нажмите любую клавишу"

// size constants
self.key_scale = 2
self.key_shift = 3
self.magic_shift = 7
self.line_interval = 10
self.key_width  = self.key_scale * sprite_get_width(sKeyX)
self.key_height = self.key_scale * sprite_get_height(sKeyX)

// find center
self.room_center_x = room_width / 2
self.room_center_y = room_height / 2
self.start_x = self.room_center_x - 130
self.start_y = self.room_center_y - 70

// alpha settings
self.text_alpha = 0.9
self.sprite_alpha = 0.9

self.text_continue_alpha_min = 0.1
self.text_continue_alpha_max = 0.6
self.text_continue_alpha_current = 0.5

// time
self.tick_counter = 0