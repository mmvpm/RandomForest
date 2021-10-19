function funPlayerJumpStart() {
	self.sprite_index = sPlayerJump
	self.current_yspeed = self.jump_impulse
}


function funPlayerJumpLogic() {
	var dx = key_move_right_pressed - key_move_left_pressed // -1, 0, +1
	
	if (dx != 0) {
		self.image_xscale = dx
	}

	self.current_xspeed = dx * self.step_xspeed
	self.current_yspeed += self.gravitation
	
	if (self.current_yspeed >= 0) {
		self.current_yspeed = 0
	}
	funPlayerStepMove()
	
	var end_jump = self.current_yspeed == 0 // float ?
	if (end_jump) {
		var detected_state = funPlayerDetectState()
		funPlayerChangeState(detected_state)
		return
	}

	// TODO: attack and hurt
}