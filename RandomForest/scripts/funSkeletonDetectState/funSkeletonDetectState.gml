/// Returns only immediate skeleton states that are safe to enter.
function funSkeletonDetectState() {
	var critical_state = funSkeletonDetectCriticalState()
	if (critical_state != undefined) {
		return critical_state
	}

	if (funEnemyPositionIsDangerous(self.x, self.y)) {
		var escape_direction = funEnemyGetEscapeDirection()
		if (escape_direction != 0) {
			self.escape_hazard = true
			self.current_direction = escape_direction
			return skeleton_states.move
		}
	}

	if (funSkeletonWantAttack()) {
		return skeleton_states.attack
	}

	if (funSkeletonSeePlayer()) {
		if (self.react_needed) {
			return skeleton_states.react
		}
	}

	return undefined
}
