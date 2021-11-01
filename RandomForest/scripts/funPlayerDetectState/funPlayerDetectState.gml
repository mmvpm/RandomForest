function funPlayerDetectState() {
	// unconditional jump
	var critical_state = funPlayerDetectCriticalState()
	if (critical_state != undefined) {
		return critical_state
	}

	// jumping
	// self.is_on_ground already computed in the beginning of `step`
	var is_fall = !self.is_on_ground and self.current_yspeed >= 0
	var is_jump = !self.is_on_ground and self.current_yspeed < 0
	var want_jump = self.jump_buffer_counter > 0
	var new_jump_allowed = funPlayerNewJumpAllowed()

	if (want_jump and new_jump_allowed) {
		return player_states.prejump
	}
	if (is_fall) {
		return player_states.fall
	}
	if (is_jump) {
		return player_states.jump
	}
	
	// moving
	var is_move = self.key_move_left_pressed || self.key_move_right_pressed
	
	if (is_move) {
		return player_states.move
	}
	if (self.is_on_ground) {
		return player_states.idle
	}

	// nothing
	return undefined
}