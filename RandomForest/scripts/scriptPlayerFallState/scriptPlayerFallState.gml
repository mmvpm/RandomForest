/// Selects the falling animation for the current skin.
function funPlayerFallStart() {
	self.sprite_index = funPlayerSkinSprite(sPlayerFall)
	self.image_index = 0
}


/// Moves downward, checks another jump, and handles landing.
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

	// jump
	var want_jump = self.jump_buffer_counter > 0
	var new_jump_allowed = funPlayerNewJumpAllowed()
	if (new_jump_allowed and want_jump) {
		funPlayerChangeState(player_states.prejump)
		return
	}

	var end_fall = self.current_yspeed == 0 // float ?
	if (end_fall) {
		funPlayerFallEnd()
		var detected_state = funPlayerDetectState()
		funPlayerChangeState(detected_state)
	}
}


/// Plays the landing feedback after a normal fall.
function funPlayerFallEnd() {
	instance_create_depth(self.x, self.y, self.depth - 1, oPlayerLandingEffect) // under player by Z
	audio_play_sound(soundPlayerLanding, 1, false)
}