if (keyboard_check_pressed(global.key_pause)) {
	self.paused = !self.paused
	if (!sprite_exists(self.screenshot)) {
		self.screenshot = sprite_create_from_surface(application_surface, 
			0, 0, room_width, room_height, 
			0, 0, 0, 0)
	}
}

if (self.paused) {
	instance_deactivate_all(true)
} else {
	if (sprite_exists(self.screenshot)) {
		sprite_delete(self.screenshot)
	}
	instance_activate_all()
}