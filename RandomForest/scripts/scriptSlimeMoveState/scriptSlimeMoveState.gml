function funSlimeMoveStart() {
	self.sprite_index = sSlimeIdle
	self.image_index = 0

	self.current_direction *= -1
	if (self.current_direction != 0) {
		self.image_xscale = self.current_direction * abs(self.image_xscale)
	}
	self.current_move_distance = self.move_distance
}


function funSlimeMoveLogic() {
	self.current_move_distance -= 1
	
	self.current_xspeed = self.current_direction * self.step_xspeed

	var success_xmove = true
	var want_move = self.current_move_distance > 0
	var fully_on_ground = funDefaultFullyOnGround()
	if (!want_move or !fully_on_ground) {
		self.current_xspeed = 0
		success_xmove = false
	}
	if (!funDefaultStepMove()) {
		success_xmove = false
	}

	if (!success_xmove) {
		funDefaultChangeState(slime_states.idle)
		return
	}
	
	var detected_state = funSlimeDetectState() // critical states here
	if (detected_state != self.state) {
		funDefaultChangeState(detected_state)
		return
	}
}