function funSlimeHurtStart() {
	self.sprite_index = sSlimeHurt
	self.image_index = 0
	self.hurt_animation_ended = false
	self.hurt_countdown_counter = self.hurt_countdown
	
	self.health = max(0, self.health - 1) // const ?
	
	self.current_xspeed = -sign(self.image_xscale) * self.hurt_ximpulse
}


function funSlimeHurtLogic() {
	funDefaultStepMove()
	
	if (self.health == 0) {
		funDefaultChangeState(slime_states.die)
		return
	}
	
	if (self.hurt_animation_ended) {
		var detected_state = funSlimeDetectState()
		funDefaultChangeState(detected_state)
		return
	}
}