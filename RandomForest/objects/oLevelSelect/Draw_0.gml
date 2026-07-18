gpu_set_tex_filter(true)

var cam = view_camera[0]
var cam_w = camera_get_view_width(cam)
var cam_h = camera_get_view_height(cam)

// Build the blurred background once for this room.
if (!surface_exists(self.back_surf)) {
	var surface_w = ceil(cam_w * self.back_scale)
	var surface_h = ceil(cam_h * self.back_scale)
	var tmp_surf = surface_create(surface_w, surface_h)
	surface_set_target(tmp_surf)
	draw_sprite(sBackground_x13, 0, 0, 0)
	surface_reset_target()

	self.back_surf = funBlurSurface(
		tmp_surf, 10,
		surface_w, surface_h,
		1, 4,
		0, 0, 0, 0.2
	)
	surface_free(tmp_surf)
}

draw_set_color(c_black)
draw_rectangle(0, 0, cam_w, cam_h, false)
draw_set_color(c_white)
draw_surface(self.back_surf, -self.back_x, -self.back_y)

draw_set_color(c_white)
draw_set_alpha(1)
gpu_set_tex_filter(false)
