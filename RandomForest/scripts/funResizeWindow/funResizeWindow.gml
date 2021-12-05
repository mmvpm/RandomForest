function funResizeWindow() {
	global.scale = 3

	var cam = room_get_camera(rLevel00, 0)
	var cam_width = camera_get_view_width(cam)
	var cam_height = camera_get_view_height(cam)
	var window_width_scaled = cam_width * global.scale
	var window_height_scaled = cam_height * global.scale

	for (var i = room_first; i != -1; i = room_next(i)) {
		var viewport = room_get_viewport(i, 0)
		room_set_camera(i, 0, cam)
		room_set_viewport(i, 0,
			viewport[0], viewport[1], viewport[2],
			window_width_scaled, window_height_scaled
		)
	}

	surface_resize(application_surface, cam_width, cam_height)

	window_set_size(window_width_scaled, window_height_scaled)
}