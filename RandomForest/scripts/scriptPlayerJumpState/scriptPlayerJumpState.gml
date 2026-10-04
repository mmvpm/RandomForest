/// Selects the upward movement animation for the current skin.
function funPlayerJumpStart() {
	self.sprite_index = funPlayerSkinSprite(sPlayerJump)
	self.image_index = 0
}


/// Moves upward and accepts a fresh unlocked airborne jump.
function funPlayerJumpLogic() {
	var dx = key_move_right_pressed - key_move_left_pressed // -1, 0, +1
	
	if (dx != 0) {
		self.image_xscale = dx
	}

	self.current_xspeed = dx * self.step_xspeed
	
	if (self.current_yspeed >= 0) {
		self.current_yspeed = 0
	}
	funPlayerStepMove()
	
	var critical_state = funPlayerDetectCriticalState()
	if (critical_state != undefined) {
		funPlayerChangeState(critical_state)
		return
	}
	
    if (self.jump_buffer_counter > 0 and funPlayerNewJumpAllowed()) {
        funPlayerChangeState(player_states.prejump)
        return
    }

	var end_jump = self.current_yspeed == 0 // float ?
	if (end_jump) {
		var detected_state = funPlayerDetectState()
		funPlayerChangeState(detected_state)
		return
	}
}