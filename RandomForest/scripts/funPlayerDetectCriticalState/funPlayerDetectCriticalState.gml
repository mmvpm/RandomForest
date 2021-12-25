function funPlayerDetectCriticalState() {
	// hurt
	var is_trapped = place_meeting(self.x, self.y, oTrap)
	var placed_enemy = instance_place(self.x, self.y, oEnemy)
	var is_hit_by_enemy = placed_enemy != noone
	if (is_hit_by_enemy) {
		is_hit_by_enemy = // extra conditions
			is_hit_by_enemy and
			placed_enemy.state != slime_states.die and
			placed_enemy.state != bungalo_states.die and  // ~ empty collision mask on die sprite
			placed_enemy.state != skeleton_states.die
	}
	var hurt_allowed = self.hurt_countdown_counter == 0

	if (hurt_allowed) {

		if (is_hit_by_enemy) {
			var nearest_enemy = instance_place(self.x, self.y, oEnemy)
			var direction_to_nearest_enemy = sign(nearest_enemy.x - self.x)
			if (direction_to_nearest_enemy != 0) {
				self.direction_to_enemy = direction_to_nearest_enemy
			}
			
			self.future_damage = nearest_enemy.damage
		}
		else if (is_trapped) {
			var nearest_trap = instance_place(self.x, self.y, oTrap)
			self.future_damage = nearest_trap.damage
		}

		if (is_trapped or is_hit_by_enemy) {
			return player_states.hurt
		}
	}

	// attack
	var want_attack = self.key_attack_pressed
	var attack_allowed = self.has_sword and self.cooldown_counter == 0

	if (want_attack and attack_allowed) {
		return player_states.attack
	}

	// nothing special
	return undefined
}