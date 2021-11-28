function funPlayerPreJumpStart() {
	self.sprite_index = sPlayerJump
	self.image_index = 0
	self.current_yspeed = self.jump_impulse
	instance_create_depth(self.x, self.y, self.depth + 1, oPlayerJumpEffect) // under player by Z
	// audio_play_sound(soundPlayerJump, 1, false) // still no sound
}


function funPlayerPreJumpLogic() {
	funPlayerStepMove()

	var critical_state = funPlayerDetectCriticalState()
	if (critical_state != undefined) {
		funPlayerChangeState(critical_state)
		return
	}

	funPlayerChangeState(player_states.jump)
}