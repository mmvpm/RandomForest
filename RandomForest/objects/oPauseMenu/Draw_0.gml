if (self.paused) {
	gpu_set_tex_filter(true)
	gpu_set_blendenable(false)

	var cam = view_camera[0]
	draw_sprite(
		self.screenshot, 0,
		camera_get_view_x(cam),
		camera_get_view_y(cam)
	)
	
	gpu_set_blendenable(true)
}