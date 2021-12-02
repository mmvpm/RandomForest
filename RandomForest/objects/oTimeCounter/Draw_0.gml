// set position on the screen
self.x = 480 - 12 - 20 // magic
self.y = 10

// keep position on the screen when camera move
self.x += camera_get_view_x(view_camera[0])
self.y += camera_get_view_y(view_camera[0])

// set up font
draw_set_halign(fa_left)
draw_set_valign(fa_top)
draw_set_font(self.default_font)

// draw time

var time_to_show = funGetTimeString(self.time_counter)
draw_text(self.x, self.y, time_to_show)