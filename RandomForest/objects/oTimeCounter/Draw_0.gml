if (not self.timer_drawing_enabled) {
	return
}

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
var minutes = floor(self.time_counter / 60)
var seconds = floor(self.time_counter % 60)
var string_minutes = string(minutes)
var string_seconds = string(seconds)

if (minutes < 10) {
	string_minutes = "0" + string_minutes
}
if (seconds < 10) {
	string_seconds = "0" + string_seconds
}

var time_to_show = string_minutes + ":" + string_seconds
draw_text(self.x, self.y, time_to_show)