function funBungaloAttackStart() {
	self.sprite_index = sBungaloAttack

	if (self.defense_activated) {
		self.image_index = self.attack_frame
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

	if (self.defense_activated and self.image_index >= self.attack_frame - 0.5) {
		self.image_index = self.attack_frame // fast-pass for defense
		self.defense_activated = false
	}

	if (self.image_index >= self.attack_frame and !self.sword_created) {
		var created_sword = instance_create_depth(self.x, self.y, -1, oBungaloSword)
		created_sword.owner_id = self
		self.sword_created = true
		audio_play_sound(soundBungaloAttack, 1, false)
	}
	if (self.image_index >= self.attack_frame + 2 and !self.sword_destroyed) {
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
	self.defense_activated = false
}