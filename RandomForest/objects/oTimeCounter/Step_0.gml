if (keyboard_check_pressed(vk_anykey)) {
	self.may_count = true // timer starts after any player response
}

if (keyboard_check_pressed(ord("T"))) {
	self.timer_drawing_enabled = !self.timer_drawing_enabled
}

if (self.may_count) {
	self.time_counter += 1
}