var cam = view_camera[0]
var cam_w = camera_get_view_width(cam)
var cam_h = camera_get_view_height(cam)
var cam_x = camera_get_view_x(cam)
var cam_y = camera_get_view_y(cam)

var _light_u_pos = self.light_u_pos
var _light_power = self.light_power
var _light_radius = self.light_radius
var _light_fov = self.light_fov
var _light_dir = self.light_dir


var _shadow_u_pos = self.shadow_u_pos

var _vb = self.vb

if (!surface_exists(self.shadow_surf)) {
	self.shadow_surf = surface_create(cam_w, cam_h)
}

matrix_set(matrix_world, matrix_build(-cam_x, -cam_y, 0, 0, 0, 0, 1, 1, 1))
surface_set_target(self.shadow_surf)
draw_clear_alpha(c_black, 0)
draw_surface_ext(
	application_surface, 
	cam_x, cam_y, 
	1, 1, 0, 
	c_white, 0.1
)

with (oLight) {
	gpu_set_blendmode_ext_sepalpha(bm_zero, bm_one, bm_one, bm_one)
	shader_set(shShadow)
	shader_set_uniform_f(_shadow_u_pos, self.x, self.y)
	vertex_submit(_vb, pr_trianglelist, -1)
	
	gpu_set_blendmode_ext_sepalpha(bm_inv_dest_alpha, bm_one, bm_zero, bm_zero)
	shader_set(shLight)
	shader_set_uniform_f(_light_u_pos, self.x, self.y)
	shader_set_uniform_f(_light_power, self.light_power)
	shader_set_uniform_f(_light_radius, self.radius)
	shader_set_uniform_f(_light_fov, self.fov)
	shader_set_uniform_f(_light_dir, self.dir)

	draw_surface_ext(
		application_surface, 
		cam_x, cam_y, 
		1, 1, 0, 
		self.light_color, 1.0
	)
}
surface_reset_target()

matrix_set(matrix_world, matrix_build(0, 0, 0, 0, 0, 0, 1, 1, 1))

gpu_set_blendmode_ext(bm_dest_alpha, bm_src_color)
shader_set(shShadowSurf)
draw_surface(self.shadow_surf, cam_x, cam_y)
shader_reset()
gpu_set_blendmode(bm_normal)
