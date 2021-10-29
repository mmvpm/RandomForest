function funBungaloAttackStart() {
	self.sprite_index = sBungaloAttack
	self.image_index = 0
	self.attack_animation_ended = false
	self.current_xspeed = 0
	self.sword_created = false
}


function funBungaloAttackLogic() {
	funDefaultStepMove()
	
	var critical_state = funBungaloDetectCriticalState()
	if (critical_state != undefined) {
		funBungaloAttackEnd()
		funDefaultChangeState(critical_state)
		return
	}
	
	if (self.image_index >= 3 and !self.sword_created) {
		instance_create_depth(self.x, self.y, -1, oBungaloSword)
		self.sword_created = true
	}
	if (self.image_index >= 5) {
		instance_destroy(oBungaloSword)
	}
	
	if (self.attack_animation_ended) {
		self.image_index = self.image_number - 1 // otherwise image_index = 0.xx, so it will be shown on 1 frame
		var detected_state = funBungaloDetectState()
		funDefaultChangeState(detected_state) // Bungalo sword already deleted
		return
	}
}


function funBungaloAttackEnd() {
	instance_destroy(oBungaloSword)
}