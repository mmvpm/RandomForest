function funPlayerDetectState() {
	var on_ground = place_meeting(self.x, self.y + 1, oSolid)
	
	var is_fall = !on_ground and self.current_yspeed >= 0
	var allowed_jump = !place_meeting(
		self.x, self.y + self.jump_impulse, oSolid
	)
	var is_jumped_now = on_ground and self.key_jump_pressed and allowed_jump
	
	var is_move = self.key_move_left_pressed || self.key_move_right_pressed


	if (is_fall) {
		return player_states.fall
	}

	if (is_jumped_now) {
		return player_states.jump
	}

	if (is_move) {
		return player_states.move
	}

	if (on_ground) {
		return player_states.idle
	}
	
	return undefined
}