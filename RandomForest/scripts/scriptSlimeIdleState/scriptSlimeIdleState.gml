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
		funSlimeChangeState(critical_state)
		return
	}
	
	funSlimeStepMove()
	
	if (self.idle_countdown_counter == 0) {
		funSlimeChangeState(slime_states.move)
		return
	}
}