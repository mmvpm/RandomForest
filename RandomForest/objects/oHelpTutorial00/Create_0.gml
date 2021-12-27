// font settings
self.text_scale_16 = 16 / 24

// text
self.arrow_keys_text = "     -     Движение персонажа"
self.collect_all_coins_text = "Собери все ягодки,\nчтобы открыть\nпортал"

// size constants
self.key_scale = 1.5
self.key_shift = 2
self.magic_shift = 7
self.key_width  = self.key_scale * sprite_get_width(sKeyX)
self.key_height = self.key_scale * sprite_get_height(sKeyX)

// positions
var cam = view_camera[0]
self.room_x0 = -camera_get_view_x(cam)
self.room_y0 = -camera_get_view_y(cam)

self.arrow_keys_start_x = self.room_x0 + 176
self.arrow_keys_start_y = self.room_y0 + 10

self.collect_coins_start_x = self.room_x0 + 70
self.collect_coins_start_y = self.room_y0 + 220

// alpha settings
self.text_alpha = 0.8
self.sprite_alpha = 0.8