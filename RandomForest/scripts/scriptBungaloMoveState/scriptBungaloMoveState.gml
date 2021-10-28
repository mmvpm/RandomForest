function funBungaloMoveStart() {
	self.sprite_index = sBungaloMove
	self.image_index = 0
}


function funBungaloMoveLogic() {	
	var direction_to_player = sign(oPlayer.x - self.x)
	if (direction_to_player != 0) {
		self.current_direction = direction_to_player
	}

	self.image_xscale = self.current_direction * abs(self.image_xscale)
	
	self.current_xspeed = self.step_xspeed * self.current_direction

	var success_xmove = true
	var is_see_player = funBungaloSeePlayer()
	var fully_on_ground = funDefaultFullyOnGround()
	
	if (!fully_on_ground or !is_see_player) {
		self.current_xspeed = 0
		success_xmove = false
	}
	if (!funDefaultStepMove()) {
		success_xmove = false
	}
	
	if (!success_xmove) {
		funDefaultChangeState(bungalo_states.idle)
		return
	}

	var detected_state = funBungaloDetectState() // critical states here
	if (detected_state != self.state) {
		funDefaultChangeState(detected_state)
		return
	}
}