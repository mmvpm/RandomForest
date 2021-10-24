function funSlimeIdleStart() {
	self.sprite_index = sSlimeIdle
	self.image_index = 0
	self.idle_countdown_counter = self.idle_countdown
	self.current_xspeed = 0
}


function funSlimeIdleLogic() {
	// detect critical states ?
	
	funSlimeStepMove()
	
	if (self.idle_countdown_counter == 0) {
		funSlimeChangeState(slime_states.move)
		return
	}
}