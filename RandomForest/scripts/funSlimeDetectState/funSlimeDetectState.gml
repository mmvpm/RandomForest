/// Returns an immediate slime state without starting ordinary patrol movement.
function funSlimeDetectState() {
	var critical_state = funSlimeDetectCriticalState()
	if (critical_state != undefined) {
		return critical_state
	}

	if (funEnemyPositionIsDangerous(self.x, self.y)) {
		var escape_direction = funEnemyGetEscapeDirection()
		if (escape_direction != 0) {
			self.escape_hazard = true
			self.current_direction = escape_direction
			return slime_states.move
		}
	}
	
	if (funSlimeSeePlayer()) {
		return slime_states.attack
	}
	
	return undefined
}
