function funPlayerDetectState() {
	// unconditional jump
	var critical_state = funPlayerDetectCriticalState()
	if (critical_state != undefined) {
		return critical_state
	}

	// jumping
	var on_ground = place_meeting(self.x, self.y + 1, oSolid)

	var is_fall = !on_ground and self.current_yspeed >= 0
	var is_jump = !on_ground and self.current_yspeed < 0
	var new_jump_allowed = on_ground and !place_meeting(
		self.x, self.y + self.jump_impulse, oSolid
	)
	var want_jump = self.key_jump_pressed

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
	if (on_ground) {
		return player_states.idle
	}

	// nothing
	return undefined
}