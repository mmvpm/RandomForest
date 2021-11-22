if (keyboard_check_pressed(global.key_pause)) {
	self.paused = !self.paused
	self.current_index = 0
	if (!surface_exists(self.screenshot)) {
		self.screenshot = funBlurSurface(
			application_surface, 10,
			surface_get_width(application_surface),
			surface_get_height(application_surface),
			1, 4,
			0, 0, 0, 0.2
		)
	}
}

if (self.paused) {
	instance_deactivate_all(true)
	
	if (keyboard_check_pressed(vk_enter)) {
		if (self.current_index == 0) {
			self.paused = false
		} else if (self.current_index == 1) {
			room_restart()
		} else if (self.current_index == 2) {
			game_end()
		}
	} else if (keyboard_check_pressed(vk_down)) {
		self.current_index += 1
		self.current_index %= self.items_count
	} else if (keyboard_check_pressed(vk_up)) {
		self.current_index += (self.items_count - 1)
		self.current_index %= self.items_count
	}
} else {
	if (surface_exists(self.screenshot)) {
		surface_free(self.screenshot)
	}
	instance_activate_all()
}