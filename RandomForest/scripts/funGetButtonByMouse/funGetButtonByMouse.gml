function funGetButtonByMouse(x_left, x_right, y_top, y_bottom, x_shift, y_shift, cam, mouse_move_required = false) {
	var n_buttons = array_length(x_left)

	// coordinates on screen
	var view_mouse_x = mouse_x - camera_get_view_x(cam)
	var view_mouse_y = mouse_y - camera_get_view_y(cam)

	if (mouse_move_required) {
		if (self.last_mouse_x == view_mouse_x and self.last_mouse_y == view_mouse_y) {
			return -1 // no mouse move
		}
	}

	for (var i = 0; i < n_buttons; ++i) {
		// if inside i-th button
		if (y_top[i]  - y_shift <= view_mouse_y and view_mouse_y <= y_bottom[i] + y_shift and
			x_left[i] - x_shift <= view_mouse_x and view_mouse_x <= x_right[i]  + x_shift) {
			if (mouse_move_required) {
				self.last_mouse_x = view_mouse_x
				self.last_mouse_y = view_mouse_y
			}
			return i
		}
	}

	return -1 // no button
}