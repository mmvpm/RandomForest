function funPlayerFallStart() {
	self.sprite_index = sPlayerFall
}


function funPlayerFallLogic() {
	var dx = key_move_right_pressed - key_move_left_pressed // -1, 0, +1
	
	if (dx != 0) {
		self.image_xscale = dx
	}

	self.current_xspeed = dx * self.step_xspeed
	self.current_yspeed += self.gravitation
	funPlayerStepMove()
	
	var end_fall = self.current_yspeed == 0 // float ?
	if (end_fall) {
		var detected_state = funPlayerDetectState()
		funPlayerChangeState(detected_state)
	}

	// TODO: attack and hurt
}