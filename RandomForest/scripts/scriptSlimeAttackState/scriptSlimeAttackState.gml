/// Starts one slime approach.
function funSlimeAttackStart() {
	self.sprite_index = sSlimeAttack
	self.image_index = 0
	self.image_speed = 1
	self.current_xspeed = 0
}


/// Pursues a visible player without moving away from them.
function funSlimeAttackLogic() {
	if (2 <= self.image_index and self.image_index <= 3 and !audio_is_playing(soundSlimeAttack)) {
		audio_play_sound(soundSlimeAttack, 1, false)
	}

	var critical_state = funSlimeDetectCriticalState()
	if (critical_state != undefined) {
		funDefaultChangeState(critical_state)
		return
	}

	if (self.air_navigation_active) {
		funEnemyApplyAirMovement()
		funDefaultStepMove()
		funEnemyFinishAirMovement()
		return
	}

	if (!funSlimeSeePlayer()) {
		funDefaultChangeState(slime_states.idle)
		return
	}

	if (!funEnemyTryPursuitAction(oPlayer.x, oPlayer.bbox_bottom, -4, 1)) {
		self.current_xspeed = 0
		funDefaultStepMove()
		return
	}

	if (self.air_navigation_active) {
		funEnemyApplyAirMovement()
		funDefaultStepMove()
		funEnemyFinishAirMovement()
		return
	}

	self.current_xspeed = self.step_xspeed * self.current_direction
	funDefaultStepMove()
}
