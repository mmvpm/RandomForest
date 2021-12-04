function funUpdateFullscreen() {
	if (global.is_fullscreen) {
		window_set_fullscreen(true)
	}
	else {
		window_set_fullscreen(false)

		var cam = room_get_camera(rLevel00, 0)
		var cam_width = camera_get_view_width(cam)
		var cam_height = camera_get_view_height(cam)
		var window_width_scaled = cam_width * global.scale
		var window_height_scaled = cam_height * global.scale

		var viewport = room_get_viewport(rLevel00, 0)

		for (var i = 0; i < room_last; i++) {
			if (i == rLoading) {
				continue
			}

			room_set_viewport(i, 0,
				viewport[0], viewport[1], viewport[2],
				window_width_scaled, window_height_scaled
			)
		}

		surface_resize(application_surface, cam_width, cam_height)

		window_set_size(window_width_scaled, window_height_scaled)
	}
}