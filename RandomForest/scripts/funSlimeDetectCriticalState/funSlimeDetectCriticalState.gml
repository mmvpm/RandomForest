function funSlimeDetectCriticalState() {
	var is_trapped = place_meeting(self.x, self.y, oTrap)
	var is_hit_by_player = place_meeting(self.x, self.y, oPlayerSword)
	if (is_trapped or is_hit_by_player) {
		return slime_states.hurt
	}
	
	return undefined
}