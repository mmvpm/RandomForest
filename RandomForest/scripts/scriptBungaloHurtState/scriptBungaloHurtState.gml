function funBungaloHurtStart() {
	self.sprite_index = sBungaloHurt
	self.image_index = 0
	self.hurt_animation_ended = false
	self.current_xspeed = 0
	
	self.health = max(0, self.health - 1) // const ?
}

function funBungaloHurtLogic() {
	funDefaultStepMove()
	
	if (self.health == 0) {
		funDefaultChangeState(bungalo_states.die)
		return
	}
	
	if (self.hurt_animation_ended) {
		var detected_state = funBungaloDetectState()
		funDefaultChangeState(detected_state)
		return
	}
}