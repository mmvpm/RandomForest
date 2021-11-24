function funPlayerHurtStart() {
	self.sprite_index = sPlayerHurt
	self.image_index = 0
	self.hurt_animation_ended = false
	self.hurt_countdown_counter = self.hurt_countdown

	self.health = max(0, self.health - self.future_damage)
	self.future_damage = 0 // just in case

	// add with red visual effect
	/*if (self.health == 1) {
		audio_play_sound(soundPlayerHeartBeating, 0, false)
	}*/

	var ximpulse = self.hurt_ximpulse
	var yimpulse = -self.hurt_yimpulse // up
	if (self.direction_to_enemy != undefined) {
		self.image_xscale = self.direction_to_enemy * abs(self.image_xscale)
		ximpulse *= -self.direction_to_enemy
		self.direction_to_enemy = undefined
	}
	else {
		ximpulse *= -sign(self.current_xspeed)
		yimpulse *= sign(self.current_yspeed)
		if (yimpulse == 0) {
			yimpulse = -self.hurt_yimpulse
		}
	}
	self.current_xspeed = ximpulse
	self.current_yspeed = yimpulse
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