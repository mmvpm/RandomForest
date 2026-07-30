/// Chooses the bungalo's next local combat or patrol state.
function funBungaloDetectState() {
	// critical states
	var critical_state = funBungaloDetectCriticalState()
	if (critical_state != undefined) {
		return critical_state
	}

	if (funEnemyPositionIsDangerous(self.x, self.y)) {
		self.escape_hazard = true
		return bungalo_states.move
	}

	// defense by attack
	var incoming_sword = funBungaloSeeTapSword()
	if (incoming_sword != noone) {
		self.defense_activated = true
		self.defense_sword_id = incoming_sword
		var direction_to_sword = sign(incoming_sword.x - self.x)
		if (direction_to_sword != 0) {
			self.image_xscale = direction_to_sword * abs(self.image_xscale)
		}
		return bungalo_states.attack
	}

	// attack
	if (funBungaloWantAttack()) {
		return bungalo_states.attack
	}

	// move
	if (funBungaloSeePlayer()) {
		var distance_to_player = oPlayer.x - self.x
		// Match move logic so an aligned player cannot restart movement every frame.
		if (abs(distance_to_player) < 12) {
			return bungalo_states.idle
		}

		var direction_to_player = sign(distance_to_player)
		if (direction_to_player != 0) {
			self.image_xscale = direction_to_player * abs(self.image_xscale)
		}

		if (funEnemyCanWalk(direction_to_player)) {
			return bungalo_states.move
		}
		else {
			return bungalo_states.idle
		}
	}

	// walk
	if (self.idle_countdown_counter == 0) {
		return bungalo_states.walk
	}

	// idle
	return bungalo_states.idle
}
