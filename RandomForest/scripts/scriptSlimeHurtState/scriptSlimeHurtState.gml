/// Applies pending damage and starts slime knockback.
function funSlimeHurtStart() {
	funEnemyCancelAirMovement()
	self.sprite_index = sSlimeHurt
	self.image_index = 0
	self.image_speed = 1
	self.hurt_animation_ended = false
	self.hurt_countdown_counter = self.hurt_countdown

	var applied_damage = min(self.health, self.future_damage)
	self.health = max(0, self.health - applied_damage)
	funShowDamageText(self, applied_damage, false)
	self.future_damage = 0 // just in case

	self.current_xspeed = -sign(self.image_xscale) * self.hurt_ximpulse
}


/// Finishes damage, death, or recovery after the hurt animation.
function funSlimeHurtLogic() {
	funDefaultStepMove()

	if (self.health == 0) {
		funDefaultChangeState(slime_states.die)
		return
	}

	if (self.hurt_animation_ended) {
		var detected_state = funSlimeDetectState()
		if (detected_state == slime_states.attack or detected_state == slime_states.move) {
			funDefaultChangeState(detected_state)
		}
		else {
			funDefaultChangeState(slime_states.idle)
		}
		return
	}
}
