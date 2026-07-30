/// Starts the skeleton's stationary decision state.
function funSkeletonIdleStart() {
	self.sprite_index = sSkeletonIdle
	self.image_index = 0
	self.image_speed = 1
	self.current_xspeed = 0
}


/// Chooses only an immediate reaction or a prevalidated pursuit action.
function funSkeletonIdleLogic() {
	funDefaultStepMove()
	
	var detected_state = funSkeletonDetectState()
	if (detected_state != undefined) {
		funDefaultChangeState(detected_state)
		return
	}

	if (!funSkeletonSeePlayer()) {
		return
	}

	if (funSkeletonTryStartPursuit()) {
		funDefaultChangeState(skeleton_states.move)
		return
	}

	funDefaultChangeState(skeleton_states.react)
	return
}
