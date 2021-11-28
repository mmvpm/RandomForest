function funBungaloWalkStart() {
	self.sprite_index = sBungaloMove
	self.image_index = 0
	self.current_direction *= -1
	if (self.current_direction == 0) {
		self.current_direction = 1
	}
	self.image_xscale = self.current_direction * abs(self.image_xscale)
}


function funBungaloWalkLogic() {
	if (funDefaultIsInView0()) {
		if ( (8 <= self.image_index or // last frame
			  3 <= self.image_index and self.image_index <= 4) and 
			  !audio_is_playing(soundBungaloSteps) ) {

			audio_play_sound(soundBungaloSteps, 0, false)
		}
	}

	self.image_xscale = self.current_direction * abs(self.image_xscale)
	
	self.current_xspeed = self.current_direction * self.step_xspeed

	var success_xmove = true
	var fully_on_ground = funDefaultFullyOnGround()
	
	if (!fully_on_ground) {
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