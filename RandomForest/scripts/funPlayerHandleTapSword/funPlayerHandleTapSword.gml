// returns true if oTapController was created

function funPlayerHandleTapSword() {

	// prohibited states
	switch (self.state) {
		case player_states.attack:
			return false
		//case player_states.hurt:
		//	return false
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
			else { // may not tap-attack
				// still nothing...
				return false
			}
		}
		else { // has no sword
			var success_tap = funPlayerTapToEmptyPlace()
			if (success_tap) {
				// bullshit architecture but still...
				funPlayerChangeState(player_states.teleport)
				self.image_alpha = 0
			}
			else { // failed tap
				funCameraShake(20)
			}
			funPlayerTapSwordDestroy(!success_tap)
			return false
		}
	}

	// return tap-sword back
	if (self.key_attack_pressed and !self.has_sword) {
		funPlayerTapSwordDestroy(true)
	}

	return false
}