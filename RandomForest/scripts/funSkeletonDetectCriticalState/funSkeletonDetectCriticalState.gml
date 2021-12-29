function funSkeletonDetectCriticalState() {
	// hurt
	var hurt_allowed = self.hurt_countdown_counter == 0
	var is_trapped = place_meeting(self.x, self.y, oTrap)
	var is_hit_by_player = place_meeting(self.x, self.y, oPlayerSword)

	if (is_trapped) {
		var nearest_trap = instance_nearest(self.x, self.y, oTrap)
		self.future_damage = nearest_trap.damage
		return skeleton_states.hurt
	}
	if (is_hit_by_player and hurt_allowed) {
		// turned to face the player
		var direction_to_player = sign(oPlayer.x - self.x)
		if (direction_to_player != 0) {
			self.image_xscale = abs(self.image_xscale) * direction_to_player
		}
		self.future_damage = oPlayerSword.damage
		return skeleton_states.hurt
	}

	// nothing special
	return undefined
}