function funSlimeIdleStart() {
	self.sprite_index = sSlimeIdle
	self.image_index = 0
	
	// for resuming
	if (self.idle_countdown_counter == 0) {
		self.idle_countdown_counter = self.idle_countdown
	}
	
	self.current_xspeed = 0
}


function funSlimeIdleLogic() {
	var critical_state = funSlimeDetectCriticalState()
	if (critical_state != undefined) {
		funDefaultChangeState(critical_state)
		return
	}
	
	funDefaultStepMove()
	
	if (self.idle_countdown_counter == 0) {
		funDefaultChangeState(slime_states.move)
		return
	}
}