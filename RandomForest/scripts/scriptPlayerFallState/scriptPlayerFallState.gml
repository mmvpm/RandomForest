function funPlayerFallStart() {
	self.sprite_index = sPlayerFall
	self.image_index = 0
}


function funPlayerFallLogic() {
	var dx = key_move_right_pressed - key_move_left_pressed // -1, 0, +1
	
	if (dx != 0) {
		self.image_xscale = dx
	}

	self.current_xspeed = dx * self.step_xspeed
	funPlayerStepMove()
	
	var critical_state = funPlayerDetectCriticalState()
	if (critical_state != undefined) {
		funPlayerChangeState(critical_state)
		return
	}
	
	var end_fall = self.current_yspeed == 0 // float ?
	if (end_fall) {
		var detected_state = funPlayerDetectState()
		funPlayerChangeState(detected_state)
	}
}