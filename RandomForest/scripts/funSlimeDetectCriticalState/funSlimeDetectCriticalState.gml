function funSlimeDetectCriticalState() {
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
	
	return undefined
}