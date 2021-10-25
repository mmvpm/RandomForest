function funPlayerDetectCriticalState() {
	var is_trapped = place_meeting(self.x, self.y, oTrap)
	var is_hit_by_enemy = place_meeting(self.x, self.y, oEnemy)
	if (is_trapped or is_hit_by_enemy) {
		return player_states.hurt
	}
	
	var attack_allowed = self.cooldown_counter == 0
	var want_attack = self.key_attack_pressed
	if (want_attack and attack_allowed) {
		return player_states.attack
	}

	return undefined
}