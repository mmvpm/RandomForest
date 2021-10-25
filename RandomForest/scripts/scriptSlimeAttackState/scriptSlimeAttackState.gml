function funSlimeAttackStart() {
	self.sprite_index = sSlimeAttack
	self.image_index = 0
	self.cooldown_counter = self.cooldown
}


function funSlimeAttackLogic() {
	// Player...Slime -> -1
	// Slime...Player -> +1
	self.current_direction = sign(oPlayer.x - self.x) // direction to player
	
	self.image_xscale = self.current_direction * abs(self.image_xscale)
	self.current_xspeed = self.step_xspeed * self.current_direction
	
	funDefaultStepMove()
	
	var critical_state = funSlimeDetectCriticalState()
	if (critical_state != undefined) {
		funDefaultChangeState(critical_state)
		return
	}
	
	var is_see_player = collision_circle(self.x, self.y, self.vision_radius, oPlayer, false, false)
	if (!is_see_player) {
		var detected_state = funSlimeDetectState()
		funDefaultChangeState(detected_state)
		return
	}
}