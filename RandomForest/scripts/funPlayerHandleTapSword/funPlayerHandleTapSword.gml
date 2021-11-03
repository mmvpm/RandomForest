// returns true if oTapController was created

function funPlayerHandleTapSword() {
	
	// prohibited states
	switch (self.state) {
		case player_states.hurt:
			return false
		case player_states.die:
			return false
	}
	
	// TODO: tap-sword on_ground reset
	
	// spawn tap-sword or teleport to it
	if (self.key_tap_attack_pressed) {

		if (self.has_sword) {
			var tap_attack_allowed = self.tap_attack_countdown_counter == 0
			
			if (tap_attack_allowed) {
				self.has_sword = false
				self.tap_attack_countdown_counter = self.tap_attack_countdown
				instance_create_depth(self.x, self.y - self.sprite_height / 2, self.depth, oTapController)
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