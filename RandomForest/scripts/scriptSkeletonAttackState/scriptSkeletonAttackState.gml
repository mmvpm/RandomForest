/// Starts one skeleton sword attack.
function funSkeletonAttackStart() {
	self.sprite_index = sSkeletonAttack
	self.image_index = 0
	self.image_speed = 1
	self.current_xspeed = 0
	self.sword_created = false
	self.sword_destroyed = false
	self.sword_id = noone
	self.attack_animation_ended = false
}


/// Runs one attack and immediately chooses the next combat action afterward.
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
		self.sword_id = created_sword
		self.sword_created = true
		audio_play_sound(soundSkeletonAttack, 1, false)
	}
	if (self.image_index >= 10 and !self.sword_destroyed) {
		funSkeletonAttackEnd()
		self.sword_destroyed = true
	}
	
	if (self.attack_animation_ended) {
		funSkeletonAttackEnd()
		if (funSkeletonWantAttack()) {
			funDefaultChangeState(skeleton_states.attack)
		}
		else {
			funDefaultChangeState(skeleton_states.idle)
		}
		return
	}
}


/// Destroys only the sword owned by this skeleton.
function funSkeletonAttackEnd() {
	if (instance_exists(self.sword_id)) {
		instance_destroy(self.sword_id)
	}
	self.sword_id = noone
	self.sword_destroyed = true
}
