// returns true if oTapController was created

function funPlayerHandleTapSword() {

	// prohibited states
	switch (self.state) {
		case player_states.hurt:
			return false
		case player_states.die:
			return false
	}

	// spawn tap-sword or teleport to it
	if (self.key_tap_attack_pressed) {

		if (self.has_sword) {
			var may_tap_attack =
				self.tap_attack_allowed and
				self.sword_destroyed and
				self.tap_attack_countdown_counter == 0

			if (may_tap_attack) {
				self.has_sword = false
				self.tap_attack_allowed = false
				self.tap_attack_countdown_counter = self.tap_attack_countdown
				
				var half_height = abs(self.bbox_top - self.bbox_bottom) / 2
				var tap_controller = instance_create_depth(self.x, self.y - half_height, self.depth, oTapController)
				tap_controller.shift_of_player_y = half_height
				
				return true
			}
			else { // may not attack
				// visual effect ???
				return false
			}
		}
		else { // has no sword
			var radius = 6
			var success_tap = false
			
			var new_x = 0
			var new_y = 0
			for (var dx = -radius; dx <= radius; ++dx) {
				for (var dy = -radius; dy <= radius; ++dy) {
					var new_x = oPlayerTapSword.x + 2 * dx // 2-grid
					var new_y = oPlayerTapSword.y + 2 * dy // 2-grid
					var is_place_empty = !funPlayerCollideWithSolid(new_x, new_y)	
					if (is_place_empty) {
						success_tap = true
						break
					}
				}
				if (success_tap) {
					break
				}
			}
			
			if (!success_tap) { // no empty place around tap-sword
				new_x = oPlayerTapSword.last_empty_x
				new_y = oPlayerTapSword.last_empty_y
			}
			
			// tap to sword
			self.x = new_x
			self.y = new_y
			
			funPlayerTapSwordDestroy()
			return false
		}
	}

	// return tap-sword back
	if (self.key_attack_pressed and !self.has_sword) {
		funPlayerTapSwordDestroy()
	}

	return false
}