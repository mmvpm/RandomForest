/// Starts the skeleton's existing initial reaction.
function funSkeletonReactStart() {
	self.sprite_index = sSkeletonReact
	self.image_index = 0
	self.image_speed = 1
	self.react_animation_ended = false
	self.react_needed = false
	self.current_xspeed = 0
}


/// Faces the player, then immediately chooses attack or local pursuit.
function funSkeletonReactLogic() {
	var direction_to_player = oPlayer.x - self.x
	if (abs(direction_to_player) < 12) {
		direction_to_player = 0
	}
	direction_to_player = sign(direction_to_player)

	if (direction_to_player != 0) {
		self.image_xscale = direction_to_player * abs(self.image_xscale)
	}

	funDefaultStepMove()

	var critical_state = funSkeletonDetectCriticalState()
	if (critical_state != undefined) {
		funDefaultChangeState(critical_state)
		return
	}

	if (self.react_animation_ended) {
		if (funEnemyPositionIsDangerous(self.x, self.y)) {
			var escape_direction = funEnemyGetEscapeDirection()
			if (escape_direction != 0) {
				self.escape_hazard = true
				self.current_direction = escape_direction
				funDefaultChangeState(skeleton_states.move)
				return
			}
		}

		if (funSkeletonWantAttack()) {
			funDefaultChangeState(skeleton_states.attack)
			return
		}
		if (!funSkeletonSeePlayer()) {
			funDefaultChangeState(skeleton_states.idle)
			return
		}
		if (funSkeletonTryStartPursuit()) {
			funDefaultChangeState(skeleton_states.move)
			return
		}

		// Keep a visible unreachable target in one stable animated state.
		self.sprite_index = sSkeletonReact
		self.image_index = 0
		self.image_speed = 1
		self.react_animation_ended = false
		return
	}
}
