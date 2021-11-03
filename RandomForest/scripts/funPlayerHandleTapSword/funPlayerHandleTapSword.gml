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
				instance_create_depth(self.x, self.y - half_height, self.depth, oTapController)
				return true
			}
			else {
				// visual effect ???
				return false
			}
		}
		else {
			// TODO: tap to sword
		}
	}

	// return tap-sword back
	if (self.key_attack_pressed and !self.has_sword) {
		funPlayerTapSwordDestroy()
	}

	return false
}