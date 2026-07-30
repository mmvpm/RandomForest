/// Starts one ordinary bungalo patrol walk.
function funBungaloWalkStart() {
	self.sprite_index = sBungaloMove
	self.image_index = 0
	self.current_direction *= -1
	if (self.current_direction == 0) {
		self.current_direction = 1
	}
	self.image_xscale = self.current_direction * abs(self.image_xscale)
}


/// Patrols until sight, danger, a wall, a ledge, or a stopped sword changes the state.
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

	var detected_state = funBungaloDetectState()
	if (detected_state != self.state) {
		funDefaultChangeState(detected_state)
		return
	}

	if (!funEnemyCanWalk(self.current_direction)) {
		self.current_xspeed = 0
		funDefaultChangeState(bungalo_states.idle)
		return
	}

	funDefaultStepMove()
}
