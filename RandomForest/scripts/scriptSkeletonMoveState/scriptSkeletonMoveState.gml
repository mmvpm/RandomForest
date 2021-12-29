function funSkeletonMoveStart() {
	self.sprite_index = sSkeletonMove
	self.image_index = 0
	self.image_xscale = self.current_direction * abs(self.image_xscale)
}


function funSkeletonMoveLogic() {
	var direction_to_player = sign(oPlayer.x - self.x)
	if (direction_to_player != 0) {
		self.current_direction = direction_to_player
	}

	self.image_xscale = self.current_direction * abs(self.image_xscale)
	
	self.current_xspeed = self.step_xspeed * self.current_direction
	
	var success_xmove = true
	var fully_on_ground = funDefaultFullyOnGround()
	var dangerous_move = place_meeting(self.x + self.current_xspeed, self.y, oTrap)
	if (!fully_on_ground or dangerous_move) {
		self.current_xspeed = 0
		success_xmove = false
	}
	if (!funDefaultStepMove()) {
		success_xmove = false
	}
	
	if (!success_xmove) {
		funDefaultChangeState(skeleton_states.idle)
		return
	}

	var detected_state = funSkeletonDetectState() // critical states here
	if (detected_state != self.state and detected_state != skeleton_states.react) {
		funDefaultChangeState(detected_state)
		return
	}
}