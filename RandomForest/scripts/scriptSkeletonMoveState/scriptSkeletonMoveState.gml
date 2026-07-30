/// Starts a real local pursuit action and reports whether one was found.
function funSkeletonTryStartPursuit() {
	if (!funSkeletonSeePlayer()) {
		return false
	}

	return funEnemyTryPursuitAction(oPlayer.x, oPlayer.bbox_bottom, -6, 2)
}

/// Starts skeleton pursuit or hazard escape.
function funSkeletonMoveStart() {
	self.sprite_index = sSkeletonMove
	self.image_index = 0
	self.image_speed = 1
	self.current_xspeed = 0
	if (self.current_direction != 0) {
		self.image_xscale = self.current_direction * abs(self.image_xscale)
	}
}


/// Moves locally toward the player while using safe jumps and platform drops.
function funSkeletonMoveLogic() {
	var critical_state = funSkeletonDetectCriticalState()
	if (critical_state != undefined) {
		funDefaultChangeState(critical_state)
		return
	}

	if (self.air_navigation_active) {
		self.image_speed = 0
		funEnemyApplyAirMovement()
		funDefaultStepMove()
		if (funEnemyFinishAirMovement()) {
			self.image_speed = 1
			funDefaultChangeState(skeleton_states.idle)
			return
		}
		return
	}

	if (self.escape_hazard) {
		var escape_direction = funEnemyGetEscapeDirection()
		if (escape_direction == 0) {
			self.escape_hazard = false
			self.current_xspeed = 0
			funDefaultChangeState(skeleton_states.idle)
			return
		}
		self.current_direction = escape_direction
		self.image_xscale = escape_direction * abs(self.image_xscale)
		self.image_speed = 1
		self.current_xspeed = escape_direction * self.step_xspeed
		funDefaultStepMove()
		if (!funEnemyPositionIsDangerous(self.x, self.y)) {
			self.escape_hazard = false
			self.current_xspeed = 0
			funDefaultChangeState(skeleton_states.idle)
			return
		}
		return
	}

	if (!funSkeletonSeePlayer()) {
		self.image_speed = 1
		self.current_xspeed = 0
		funDefaultChangeState(skeleton_states.idle)
		return
	}

	if (funSkeletonWantAttack()) {
		self.image_speed = 1
		self.current_xspeed = 0
		funDefaultChangeState(skeleton_states.attack)
		return
	}

	if (!funSkeletonTryStartPursuit()) {
		self.image_speed = 1
		self.current_xspeed = 0
		funDefaultChangeState(skeleton_states.react)
		return
	}

	if (self.air_navigation_active) {
		self.image_speed = 0
		funEnemyApplyAirMovement()
		funDefaultStepMove()
		if (funEnemyFinishAirMovement()) {
			self.image_speed = 1
			funDefaultChangeState(skeleton_states.idle)
			return
		}
		return
	}

	self.image_speed = 1
	self.current_xspeed = self.step_xspeed * self.current_direction
	funDefaultStepMove()
}
