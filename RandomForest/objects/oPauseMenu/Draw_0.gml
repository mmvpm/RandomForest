if (self.paused) {
	gpu_set_tex_filter(true)
	
	var cam = view_camera[0]
	draw_surface(self.screenshot, 
		camera_get_view_x(cam),
		camera_get_view_y(cam)
	)
}
