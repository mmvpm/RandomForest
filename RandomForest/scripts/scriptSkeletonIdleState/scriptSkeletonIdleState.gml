function funSkeletonIdleStart() {
	self.sprite_index = sSkeletonIdle
	self.image_index = 0	
	self.current_xspeed = 0
}


function funSkeletonIdleLogic() {
	// critical states ??
	
	funDefaultStepMove()
	
	var detected_state = funSkeletonDetectState()
	if (detected_state != self.state) {
		funDefaultChangeState(detected_state)
		return
	}
}