// returns true if oTapController was created

function funPlayerHandleTapSword() {
	
	if (self.key_tap_attack_pressed and 
		self.state != player_states.die and 
		self.state != player_states.hurt) {

		if (self.has_sword) {
			self.has_sword = false
			instance_create_depth(self.x, self.y - self.sprite_height / 2, self.depth, oTapController)
			return true
		}
		else {
			// TODO: tap to sword
			// TODO: return sword back
		}
	}
	
	return false
}