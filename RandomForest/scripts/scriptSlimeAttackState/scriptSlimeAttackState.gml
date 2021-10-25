function funSlimeAttackStart() {
	self.sprite_index = sSlimeAttack
	self.image_index = 0
}


function funSlimeAttackLogic() {
	// Player...Slime -> -1
	// Slime...Player -> +1
	var direction_to_player = sign(oPlayer.x - self.x)
	
	self.current_xspeed = self.step_xspeed * direction_to_player
	
	funSlimeStepMove()
	
	var critical_state = funSlimeDetectCriticalState()
	if (critical_state != undefined) {
		funSlimeChangeState(critical_state)
		return
	}
	
	var is_see_player = collision_circle(self.x, self.y, self.vision_radius, oPlayer, false, false)
	if (!is_see_player) {
		var detected_state = funSlimeDetectState()
		funSlimeChangeState(detected_state)
		return
	}
}