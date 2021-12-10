if (keyboard_check_pressed(global.key_pause)) {
	self.paused = !self.paused
	self.current_index = 0
	if (self.paused) {
		var cam = view_camera[0]
		var cam_w = camera_get_view_width(cam)
		var cam_h = camera_get_view_height(cam)
		var surf = funBlurSurface(
			application_surface, 10,
			cam_w, cam_h,
			1, 4,
			0, 0, 0, 0.2
		)
		self.screenshot = sprite_create_from_surface(
			surf, 0, 0, 
			cam_w, cam_h,
			0, 0, 0, 0
		)
		surface_free(surf)
	} else {
		sprite_delete(self.screenshot)
	}
}

if (self.paused) {
	instance_deactivate_all(true)
	instance_activate_object(oDebug)
	instance_activate_object(oFullscreen)

	if (keyboard_check_pressed(vk_enter)) {
		if (self.current_index == 0) {
			self.paused = false
		}
		else if (self.current_index == 1) {
			room_restart()
		}
		else if (self.current_index == 2) {
			game_end()
		}
	}
	else if (keyboard_check_pressed(vk_down)) {
		self.current_index += 1
		self.current_index %= self.items_count
		audio_play_sound(soundMenuButton, 0, false)
	}
	else if (keyboard_check_pressed(vk_up)) {
		self.current_index += (self.items_count - 1)
		self.current_index %= self.items_count
		audio_play_sound(soundMenuButton, 0, false)
	}
}
else {
	instance_activate_all()
}