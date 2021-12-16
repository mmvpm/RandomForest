function funBungaloAttackStart() {
	self.sprite_index = sBungaloAttack

	if (self.defense_activated) {
		self.image_index = 2
		self.defense_activated = false
	}
	else {
		self.image_index = 0
	}

	self.attack_animation_ended = false
	self.current_xspeed = 0
	self.sword_created = false
	self.sword_destroyed = false
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
		var created_sword = instance_create_depth(self.x, self.y, -1, oBungaloSword)
		created_sword.owner_id = self
		self.sword_created = true
		audio_play_sound(soundBungaloAttack, 1, false)
	}
	if (self.image_index >= 5 and !self.sword_destroyed) {
		instance_destroy(oBungaloSword)
		self.sword_destroyed = true
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