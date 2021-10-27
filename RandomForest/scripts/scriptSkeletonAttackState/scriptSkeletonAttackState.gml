function funSkeletonAttackStart() {
	self.sprite_index = sSkeletonAttack
	self.image_index = 0
	self.attack_animation_ended = false
	self.current_xspeed = 0
	self.sword_created = false
}


function funSkeletonAttackLogic() {
	funDefaultStepMove()
	
	var critical_state = funSkeletonDetectCriticalState()
	if (critical_state != undefined) {
		funSkeletonAttackEnd()
		funDefaultChangeState(critical_state)
		return
	}
	
	if (self.image_index >= 7 and !self.sword_created) {
		instance_create_depth(self.x, self.y, -1, oSkeletonSword)
		self.sword_created = true
	}
	if (self.image_index >= 10) {
		instance_destroy(oSkeletonSword)
	}
	
	if (self.attack_animation_ended) {
		var detected_state = funSkeletonDetectState()
		funDefaultChangeState(detected_state) // skeleton sword already deleted
		return
	}
}

function funSkeletonAttackEnd() {
	instance_destroy(oSkeletonSword)
}