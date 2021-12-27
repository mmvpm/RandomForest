// font settings
self.text_scale_16 = 16 / 24

// text
self.help_top_text = "Ты можешь бросить меч только 1 раз"
self.help_bottom_text = "Но счётчик сбрасывается, когда персонаж касается земли"

// size constants
self.key_scale = 2
self.key_shift = 3
self.magic_shift = 7
self.key_width  = self.key_scale * sprite_get_width(sKeyX)
self.key_height = self.key_scale * sprite_get_height(sKeyX)

// positions
var cam = view_camera[0]
self.room_x0 = -camera_get_view_x(cam)
self.room_y0 = -camera_get_view_y(cam)

self.room_center_x = camera_get_view_width(cam) / 2
self.room_bottom_y = camera_get_view_height(cam)

self.help_top_start_x = self.room_center_x
self.help_top_start_y = self.room_y0 + 14

self.help_bottom_start_x = self.room_center_x
self.help_bottom_start_y = self.room_bottom_y - 18

// alpha settings
self.text_alpha = 0.8
self.sprite_alpha = 0.8