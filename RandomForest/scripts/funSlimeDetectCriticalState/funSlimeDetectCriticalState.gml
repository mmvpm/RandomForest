/// Returns an immediate damage state for the slime, if one is allowed.
function funSlimeDetectCriticalState() {
	// hurt
	var hurt_allowed = self.hurt_countdown_counter == 0
	var is_trapped = place_meeting(self.x, self.y, oTrap)
	var is_hit_by_player = place_meeting(self.x, self.y, oPlayerSword)
	
	if (is_trapped and hurt_allowed) {
		var overlapping_trap = instance_place(self.x, self.y, oTrap)
		self.future_damage = overlapping_trap.damage
		return slime_states.hurt
	}
	if (is_hit_by_player and hurt_allowed) {
		// turned to face the player
		var direction_to_player = sign(oPlayer.x - self.x)
		if (direction_to_player != 0) {
			self.image_xscale = abs(self.image_xscale) * direction_to_player
		}
		self.future_damage = oPlayerSword.damage
		return slime_states.hurt
	}
	
    if (hurt_allowed) {
        var wave = funPlayerStompWaveDamage()
        if (wave != noone) {
            var direction_to_wave = sign(wave.x - self.x)
            if (direction_to_wave != 0) self.image_xscale = abs(self.image_xscale) * direction_to_wave
            self.future_damage = 1
            return slime_states.hurt
        }
    }

	// nothing special
	return undefined
}
