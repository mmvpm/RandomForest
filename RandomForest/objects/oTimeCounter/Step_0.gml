if (keyboard_check_pressed(vk_anykey)) {
	self.may_count = true // timer starts after any player response
}

if (self.may_count) {
	self.time_counter += 1
}