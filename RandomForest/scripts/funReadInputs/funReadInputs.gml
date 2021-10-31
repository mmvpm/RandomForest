function funReadInputs() {
	self.key_move_left_pressed = keyboard_check(global.key_move_left)
	self.key_move_right_pressed = keyboard_check(global.key_move_right)

	if (keyboard_check_pressed(global.key_jump)) {
		self.jump_buffer_counter = self.jump_buffer_max
	}
	if (keyboard_check_pressed(global.key_fall)) {
		self.fall_buffer_counter = self.fall_buffer_max
	}
	self.key_attack_pressed = keyboard_check_pressed(global.key_attack)
}