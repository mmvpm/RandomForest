/// Consumes one jump request and starts the upward impulse.
function funPlayerPreJumpStart() {
	self.sprite_index = funPlayerSkinSprite(sPlayerJump)
	self.image_index = 0
	funPlayerConsumeJump()
	self.current_yspeed = self.jump_impulse
	instance_create_depth(self.x, self.y, self.depth + 1, oPlayerJumpEffect) // under player by Z
	// audio_play_sound(soundPlayerJump, 1, false) // still no sound
}


/// Moves the first jump frame before entering ordinary airborne movement.
function funPlayerPreJumpLogic() {
	funPlayerStepMove()

	var critical_state = funPlayerDetectCriticalState()
	if (critical_state != undefined) {
		funPlayerChangeState(critical_state)
		return
	}

	funPlayerChangeState(player_states.jump)
}