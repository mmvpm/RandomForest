function funPlayerMoveStart() {
	self.sprite_index = sPlayerMove
	self.image_index = 0
}


function funPlayerMoveLogic() {
	var dx = key_move_right_pressed - key_move_left_pressed // -1, 0, +1

	if (dx != 0) {
		self.image_xscale = dx
	}

	self.current_xspeed = dx * self.step_xspeed
	funPlayerStepMove()

	var detected_state = funPlayerDetectState()
	if (detected_state != player_states.move) {
		funPlayerChangeState(detected_state)
		return
	}
}
