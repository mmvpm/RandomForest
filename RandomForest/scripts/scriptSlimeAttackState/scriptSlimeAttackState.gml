function funSlimeAttackStart() {
	self.sprite_index = sSlimeAttack
	self.image_index = 0
	self.cooldown_counter = self.cooldown
}


function funSlimeAttackLogic() {
	var direction_to_player = sign(oPlayer.x - self.x)
	if (direction_to_player != 0) {
		self.current_direction = direction_to_player
	}
	
	self.image_xscale = self.current_direction * abs(self.image_xscale)
	
	self.current_xspeed = self.step_xspeed * self.current_direction
	
	funDefaultStepMove()
	
	var critical_state = funSlimeDetectCriticalState()
	if (critical_state != undefined) {
		funDefaultChangeState(critical_state)
		return
	}
	
	if (!funSlimeSeePlayer()) {
		funDefaultChangeState(slime_states.idle)
		return
	}
}