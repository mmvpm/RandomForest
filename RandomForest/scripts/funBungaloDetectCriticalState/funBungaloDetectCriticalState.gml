function funBungaloDetectCriticalState() {
	// hurt
	var hurt_allowed = self.hurt_countdown_counter == 0
	var is_trapped = place_meeting(self.x, self.y, oTrap)
	var is_hit_by_player = place_meeting(self.x, self.y, oPlayerSword)
	
	if (is_trapped) {
		return bungalo_states.hurt
	}
	if (is_hit_by_player and hurt_allowed) {
		// turned to face the player
		var direction_to_player = sign(oPlayer.x - self.x)
		if (direction_to_player == 0) {
			direction_to_player = 1
		}
		self.image_xscale = abs(self.image_xscale) * direction_to_player
		return bungalo_states.hurt
	}
	
	// nothing special
	return undefined
}