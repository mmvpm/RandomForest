function funPlayerHurtStart() {
	self.sprite_index = sPlayerHurt
	self.image_index = 0
	self.hurt_animation_ended = false
	
	self.health = max(0, self.health - 2) // const ?
	
	self.current_xspeed = -self.image_xscale * self.hurt_ximpulse
	self.current_yspeed = self.hurt_yimpulse // always up
}


function funPlayerHurtLogic() {	
	funPlayerStepMove()
	
	if (self.health == 0) {
		funPlayerChangeState(player_states.die)
		return
	}
	
	if (self.hurt_animation_ended) {
		var detected_state = funPlayerDetectState()
		funPlayerChangeState(detected_state)
		return
	}
}