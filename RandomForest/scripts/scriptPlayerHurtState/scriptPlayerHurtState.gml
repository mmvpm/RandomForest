function funPlayerHurtStart() {
	self.sprite_index = sPlayerHurt
	self.image_index = 0
	self.hurt_animation_ended = false
	self.hurt_countdown_counter = self.hurt_countdown
	
	self.health = max(0, self.health - 1) // const ?
	
	self.image_xscale = self.direction_to_enemy * abs(self.image_xscale)
	self.current_xspeed = -self.direction_to_enemy * self.hurt_ximpulse
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