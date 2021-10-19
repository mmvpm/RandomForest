funReadInputs()

switch (self.state) {

	case player_states.idle:
		if (self.state_changed) {
			funPlayerIdleStart()
			self.state_changed = false
		}
		funPlayerIdleLogic()
		break

	case player_states.move:
		if (self.state_changed) {
			funPlayerMoveStart()
			self.state_changed = false
		}
		funPlayerMoveLogic()
		break
	
	case player_states.jump:
		if (self.state_changed) {
			funPlayerJumpStart()
			self.state_changed = false
		}
		funPlayerJumpLogic()
		break
	
	case player_states.fall:
		if (self.state_changed) {
			funPlayerFallStart()
			self.state_changed = false
		}
		funPlayerFallLogic()
		break
	
	
}