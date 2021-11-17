// set position on the screen
self.x = 12
self.y = 12 + 6 + 12

// keep position on the screen when camera move
self.x += camera_get_view_x(view_camera[0])
self.y += camera_get_view_y(view_camera[0])

// draw collected coins number
draw_set_halign(fa_left)
draw_set_valign(fa_middle)
draw_set_font(self.default_font)
draw_text_ext(self.x + 12 + 6, self.y - 5, self.coins_collected, 0, 12)

// draw myself
draw_self()