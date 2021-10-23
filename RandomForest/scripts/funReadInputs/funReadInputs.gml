function funReadInputs() {
	self.key_move_left_pressed = keyboard_check(global.key_move_left)
	self.key_move_right_pressed = keyboard_check(global.key_move_right)
	self.key_jump_pressed = keyboard_check_pressed(global.key_jump)
	self.key_attack_pressed = keyboard_check_pressed(global.key_attack)
}