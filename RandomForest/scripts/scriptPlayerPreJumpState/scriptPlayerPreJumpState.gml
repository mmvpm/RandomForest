function funPlayerPreJumpStart() {
	self.sprite_index = sPlayerJump
	self.current_yspeed = self.jump_impulse
}


function funPlayerPreJumpLogic() {
	funPlayerStepMove()

	var critical_state = funPlayerDetectCriticalState()
	if (critical_state != undefined) {
		funPlayerChangeState(critical_state)
		return
	}
	
	funPlayerChangeState(player_states.jump)
}