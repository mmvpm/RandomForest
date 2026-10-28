/// Collects movement edges and buffered actions for the current player step.
function funReadInputs() {
	if (funStoryEndingActive()) {
		funStoryEndingPlayerInputs()
		return
	}
	self.key_move_left_pressed = keyboard_check(global.key_move_left)
	self.key_move_right_pressed = keyboard_check(global.key_move_right)

	if (keyboard_check_pressed(global.key_jump)) {
		self.jump_buffer_counter = self.jump_buffer_max
	}
	if (keyboard_check_pressed(global.key_fall)) {
		self.fall_buffer_counter = self.fall_buffer_max
	}
	self.key_stomp_pressed = keyboard_check_pressed(vk_space)
	if (room == rBlackRoom and (instance_exists(oDialogue)
		or oBlackRoomController.space_guard > 0 or !oBlackRoomController.dialogue_finished)) {
		self.key_stomp_pressed = false
	}
	self.key_attack_pressed = keyboard_check_pressed(global.key_attack)
	self.key_tap_attack_pressed = keyboard_check_pressed(global.key_tap_attack)
}
