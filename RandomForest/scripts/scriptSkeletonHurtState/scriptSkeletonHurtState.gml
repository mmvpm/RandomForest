/// Applies pending damage and starts skeleton invulnerability.
function funSkeletonHurtStart() {
	funEnemyCancelAirMovement()
	self.sprite_index = sSkeletonHurt
	self.image_index = 0
	self.image_speed = 1
	self.current_xspeed = 0
	self.hurt_animation_ended = false
	self.hurt_countdown_counter = self.hurt_countdown
	self.react_needed = false
	
	var applied_damage = min(self.health, self.future_damage)
	self.health = max(0, self.health - applied_damage)
	funShowDamageText(self, applied_damage, false)
	self.future_damage = 0 // just in case
	funEnemyStompKnockbackStart()
}


/// Finishes damage, death, or recovery after the hurt animation.
function funSkeletonHurtLogic() {
	funDefaultStepMove()
	funEnemyStompKnockbackUpdate()
	
	if (self.health == 0) {
		funDefaultChangeState(skeleton_states.die)
		return
	}
	
	if (self.hurt_animation_ended) {
		if (funSkeletonWantAttack()) {
			funDefaultChangeState(skeleton_states.attack)
		}
		else {
			funDefaultChangeState(skeleton_states.idle)
		}
		return
	}
}
