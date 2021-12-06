gpu_set_tex_filter(true)

if (!surface_exists(self.back_surf)) {
	var cam = view_camera[0]
	var cam_w = camera_get_view_width(cam)
	var cam_h = camera_get_view_height(cam)
	
	var tmp_surf = surface_create(cam_w, cam_h)
	surface_set_target(tmp_surf)
	draw_sprite(sBackground, 0, 0, 0)
	surface_reset_target()
	
	self.back_surf = funBlurSurface(
		tmp_surf, 10,
		cam_w, cam_h,
		1, 4,
		0, 0, 0, 0.2
	)
	surface_free(tmp_surf)
}


var cur_alpha = 1 - self.alpha_animation_counter / self.alpha_animation_time

var cam = view_camera[0]
var cam_x = camera_get_view_x(cam)
var cam_y = camera_get_view_y(cam)
var cam_w = camera_get_view_width(cam)
var cam_h = camera_get_view_height(cam)

draw_set_color(c_black)
draw_rectangle(cam_x, cam_y, cam_x + cam_w, cam_y + cam_h, 0)
draw_set_color(c_white)
draw_set_alpha(cur_alpha)
draw_surface(self.back_surf, cam_x, cam_y)

// reset
draw_set_color(c_white)
draw_set_alpha(1)
