function funPlayerDetectCriticalState() {
	// hurt
	var is_trapped = place_meeting(self.x, self.y, oTrap)
	var is_hit_by_enemy = place_meeting(self.x, self.y, oEnemy)
	var hurt_allowed = self.hurt_countdown_counter == 0

	if (hurt_allowed) {

		if (is_hit_by_enemy) {
			var nearest_enemy = instance_nearest(self.x, self.y, oEnemy)
			var direction_to_nearest_enemy = sign(nearest_enemy.x - self.x)
			if (direction_to_nearest_enemy != 0) {
				self.direction_to_enemy = direction_to_nearest_enemy
			}
		}

		if (is_trapped or is_hit_by_enemy) {
			return player_states.hurt
		}
	}

	// attack
	var want_attack = self.key_attack_pressed
	var attack_allowed = self.cooldown_counter == 0

	if (want_attack and attack_allowed) {
		return player_states.attack
	}

	// nothing special
	return undefined
}