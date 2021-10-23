if (keyboard_check_pressed(global.key_pause)) {
	self.paused = !self.paused
	self.current_index = 0
	if (!sprite_exists(self.screenshot)) {
		self.screenshot = funBlurSprite(
			application_surface,
			12, room_width, room_height, 1, 0.01,
			0, 0, 0, 0.2
		)
	}
}

if (self.paused) {
	gpu_set_tex_filter(true)
	instance_deactivate_all(true)
	
	if (keyboard_check_pressed(vk_enter)) {
		if (self.current_index == 0) {
			self.paused = false
		} else if (self.current_index == 1) {
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
	shader_reset()
	if (sprite_exists(self.screenshot)) {
		sprite_delete(self.screenshot)
	}
	instance_activate_all()
}