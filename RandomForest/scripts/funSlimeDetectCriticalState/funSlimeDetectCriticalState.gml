function funSlimeDetectCriticalState() {
	// hurt
	var is_trapped = place_meeting(self.x, self.y, oTrap)
	var is_hit_by_player = place_meeting(self.x, self.y, oPlayerSword)
	
	if (is_trapped) {
		return slime_states.hurt
	}
	if (is_hit_by_player) {
		// turned to face the player
		self.image_xscale = abs(self.image_xscale) * sign(oPlayer.x - self.x)
		return slime_states.hurt
	}
	
	// attack
	var is_see_player = collision_circle(self.x, self.y, self.vision_radius, oPlayer, false, false)
	var new_attack_allowed = self.cooldown_counter == 0
	if (is_see_player and new_attack_allowed) {
		return slime_states.attack
	}
	
	// nothing special
	return undefined
}