function funSkeletonAttackStart() {
	self.sprite_index = sSkeletonAttack
	self.image_index = 0
	self.current_xspeed = 0
	self.sword_created = false
	self.sword_destroyed = false
	self.attack_animation_ended = false
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
		var created_sword = instance_create_depth(self.x, self.y, -1, oSkeletonSword)
		created_sword.owner_id = self
		self.sword_created = true
		audio_play_sound(soundSkeletonAttack, 1, false)
	}
	if (self.image_index >= 10 and !self.sword_destroyed) {
		instance_destroy(oSkeletonSword)
		self.sword_destroyed = true
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