function funSkeletonHurtStart() {
	self.sprite_index = sSkeletonHurt
	self.image_index = 0
	self.current_xspeed = 0
	self.hurt_animation_ended = false
	self.hurt_countdown_counter = self.hurt_countdown
	
	self.health = max(0, self.health - 1) // const ?
}


function funSkeletonHurtLogic() {
	funDefaultStepMove()
	
	if (self.health == 0) {
		funDefaultChangeState(skeleton_states.die)
		return
	}
	
	if (self.hurt_animation_ended) {
		var detected_state = funSkeletonDetectState()
		funDefaultChangeState(detected_state)
		return
	}
}