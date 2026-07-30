/// Starts bungalo pursuit or hazard escape.
function funBungaloMoveStart() {
	self.sprite_index = sBungaloMove
	self.image_index = 0
}


/// Moves the bungalo locally without leaving safe ground.
function funBungaloMoveLogic() {
	if (funDefaultIsInView0()) {
		if ( (8 <= self.image_index or // last frame
			  3 <= self.image_index and self.image_index <= 4) and 
			  !audio_is_playing(soundBungaloSteps) ) {

			audio_play_sound(soundBungaloSteps, 0, false)
		}
	}

	var critical_state = funBungaloDetectCriticalState()
	if (critical_state != undefined) {
		funDefaultChangeState(critical_state)
		return
	}

	if (self.escape_hazard) {
		var escape_direction = funEnemyGetEscapeDirection()
		if (escape_direction == 0) {
			self.current_xspeed = 0
			funDefaultStepMove()
			return
		}
		self.current_direction = escape_direction
		self.image_xscale = escape_direction * abs(self.image_xscale)
		self.current_xspeed = escape_direction * self.step_xspeed
		funDefaultStepMove()
		if (!funEnemyPositionIsDangerous(self.x, self.y)) {
			self.escape_hazard = false
		}
		return
	}

	if (!funBungaloSeePlayer()) {
		self.current_xspeed = 0
		funDefaultChangeState(bungalo_states.idle)
		return
	}

	var distance_to_player = oPlayer.x - self.x
	var player_is_horizontally_aligned = abs(distance_to_player) < 12
	if (!player_is_horizontally_aligned) {
		self.current_direction = sign(distance_to_player)
	}
	self.image_xscale = self.current_direction * abs(self.image_xscale)

	if (funBungaloWantAttack()) {
		self.current_xspeed = 0
		funDefaultChangeState(bungalo_states.attack)
		return
	}

	if (player_is_horizontally_aligned or !funEnemyCanWalk(self.current_direction)) {
		self.current_xspeed = 0
		funDefaultChangeState(bungalo_states.idle)
		return
	}

	self.current_xspeed = self.step_xspeed * self.current_direction
	funDefaultStepMove()
}
