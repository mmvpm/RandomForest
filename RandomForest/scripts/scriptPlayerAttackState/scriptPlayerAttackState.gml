function funPlayerAttackStart() {
	// create collision mask for sword
	var created_sword = instance_create_depth(self.x, self.y, -1, oPlayerSword)

	// go to next animation type if in combo
	if (self.attack_combo_buffer_counter > 0) {
		// {1, 2, 3} -> {2, 3, 1}
		self.attack_animation_type = self.attack_animation_type % self.attack_animation_types_number + 1
	}
	else { // start new combo
		self.attack_animation_type = 1
	}

	// choose animation type
	switch (self.attack_animation_type) {
		case 1:
			self.sprite_index = sPlayerAttack1
			created_sword.xscale_factor = 1
			created_sword.yscale_factor = 1
			break
		case 2:
			self.sprite_index = sPlayerAttack2
			created_sword.xscale_factor = 0.9
			created_sword.yscale_factor = 1.7
			break
		case 3:
			self.sprite_index = sPlayerAttack3
			created_sword.xscale_factor = 0.8
			created_sword.yscale_factor = 2.1
			break
	}

	// other parameters
	self.image_index = 0
	self.cooldown_counter = self.cooldown
	self.sword_destroyed = false
	self.attack_animation_ended = false
}


function funPlayerAttackLogic() {
	funPlayerStepMove()

	// attack interruption because of critical event
	var critical_state = funPlayerDetectCriticalState()
	if (critical_state != undefined and critical_state != player_states.attack) {
		if (!self.sword_destroyed) {
			funPlayerAttackClean()
		}
		funPlayerChangeState(critical_state)
		return
	}

	// attack interruption because of some event
	if (self.image_index >= 3) {
		if (!self.sword_destroyed) {
			funPlayerAttackClean() // always (!) destroy a sword after 3rd animation frame
		}

		var detected_state = funPlayerDetectState()
		if (detected_state != player_states.idle) {
			funPlayerChangeState(detected_state)
			return
		}
	}

	// attack end because of animantion end
	if (self.attack_animation_ended) {
		var detected_state = funPlayerDetectState()
		if (!self.sword_destroyed) {
			funPlayerAttackClean()
		}
		funPlayerChangeState(detected_state)
		return
	}
}


function funPlayerAttackClean() {
	instance_destroy(oPlayerSword)
	self.sword_destroyed = true

	self.attack_combo_buffer_counter = self.attack_combo_buffer_max
}