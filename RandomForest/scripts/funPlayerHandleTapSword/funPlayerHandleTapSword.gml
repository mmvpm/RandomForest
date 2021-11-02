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
			self.has_sword = false
			instance_create_depth(self.x, self.y - self.sprite_height / 2, self.depth, oTapController)
			return true
		}
		else {
			// TODO: tap to sword
		}
	}
	
	// return tap-sword back
	if (self.key_attack_pressed and !self.has_sword) {
		// visual effect ?
		funPlayerTapSwordDestroy()
	}
	
	return false
}