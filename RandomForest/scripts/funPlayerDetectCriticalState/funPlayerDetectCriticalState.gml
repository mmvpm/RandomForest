/// Chooses damage or attack states that interrupt ordinary player movement.
function funPlayerDetectCriticalState() {
	// hurt
	var is_trapped = place_meeting(self.x, self.y, oTrap)
	var placed_enemy = noone
	var contact_damage = 0
	var enemy_list = ds_list_create()
	var enemy_count = instance_place_list(self.x, self.y, oEnemy, enemy_list, false)
	for (var i = 0; i < enemy_count; ++i) {
		var candidate = enemy_list[| i]
		if (candidate.can_damage_player and !candidate.is_dead) {
			var damage = candidate.damage
			if (candidate.object_index == oRootMaw) with (candidate) damage = funForestMawContactDamage()
			if (damage <= 0) continue
			contact_damage = damage
			placed_enemy = candidate
			break
		}
	}
	ds_list_destroy(enemy_list)
	var is_hit_by_enemy = placed_enemy != noone
	var hurt_allowed = self.hurt_countdown_counter == 0 and !funPlayerStompInvulnerable()

	if (hurt_allowed) {

		if (is_hit_by_enemy) {
			var direction_to_nearest_enemy = sign(placed_enemy.x - self.x)
			self.forest_damage_projectile = noone
			// Forest strike x is a rectangle edge; its owner supplies the actual attack origin.
			if (variable_instance_exists(placed_enemy, "forest_kind")
				or placed_enemy.object_index == oForestStrike or placed_enemy.object_index == oForestProjectile) {
				direction_to_nearest_enemy = -funForestPlayerKnockbackDirection(placed_enemy, self.x)
				if (placed_enemy.object_index == oForestProjectile and !placed_enemy.seed_blast) {
					self.forest_damage_projectile = placed_enemy
				}
			}
			if (direction_to_nearest_enemy != 0) {
				self.direction_to_enemy = direction_to_nearest_enemy
			}
			
			self.future_damage = contact_damage
		}
		else if (is_trapped) {
			self.forest_damage_projectile = noone
			var nearest_trap = instance_place(self.x, self.y, oTrap)
			self.future_damage = nearest_trap.damage
		}

		if (is_trapped or is_hit_by_enemy) {
			return player_states.hurt
		}
	}

    // A grounded stomp cannot interrupt an attack or a one-shot story transform.
    if (self.key_stomp_pressed and self.stomp_unlocked and !self.story_pending
        and self.stomp_cooldown_counter <= 0
        and self.is_on_ground and self.state != player_states.attack
        and self.state != player_states.teleport and self.state != player_states.stomp
        and self.state != player_states.story_transform) {
        return player_states.stomp
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
