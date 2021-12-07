var w = room_width
var h = room_height

if (!surface_exists(self.back_surf)) {	
	var tmp_surf = surface_create(w, h)
	surface_set_target(tmp_surf)
	draw_sprite(sBackground, 0, 0, 0)
	surface_reset_target()
	
	self.back_surf = funBlurSurface(
		tmp_surf, 10,
		w, h,
		1, 4,
		0, 0, 0, 0.2
	)
	surface_free(tmp_surf)
}

var cur_alpha = 1 - self.alpha_animation_counter / self.alpha_animation_time

draw_set_color(c_black)
draw_rectangle(0, 0, w, h, 0)
draw_set_color(c_white)
draw_set_alpha(cur_alpha)
draw_surface(self.back_surf, 0, 0)

// reset
draw_set_color(c_white)
draw_set_alpha(1)
