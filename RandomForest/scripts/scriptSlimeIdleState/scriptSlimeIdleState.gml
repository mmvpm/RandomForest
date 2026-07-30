/// Starts the slime's stationary patrol pause.
function funSlimeIdleStart() {
	self.sprite_index = sSlimeIdle
	self.image_index = 0
	self.image_speed = 1
	self.current_xspeed = 0
	
	// Restart the patrol pause only when the previous pause has elapsed.
	if (self.idle_countdown_counter == 0) {
		self.idle_countdown_counter = self.idle_countdown
	}
}


/// Waits safely while still reacting immediately to danger or a visible player.
function funSlimeIdleLogic() {
	funDefaultStepMove()

	var detected_state = funSlimeDetectState()
	if (detected_state != undefined) {
		funDefaultChangeState(detected_state)
		return
	}

	if (self.idle_countdown_counter > 0) {
		return
	}

	if (funSlimeChoosePatrolDirection()) {
		funDefaultChangeState(slime_states.move)
		return
	}

	// A blocked slime waits instead of flashing the move sprite every frame.
	self.idle_countdown_counter = self.idle_countdown
}
