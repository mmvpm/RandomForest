function funBungaloIdleStart() {
	self.sprite_index = sBungaloIdle
	self.image_index = 0	
	self.current_xspeed = 0
	self.idle_countdown_counter = self.idle_countdown
}


function funBungaloIdleLogic() {
	funDefaultStepMove()
	
	var detected_state = funBungaloDetectState() // critical states here
	if (detected_state != self.state) {
		funDefaultChangeState(detected_state)
		return
	}
}