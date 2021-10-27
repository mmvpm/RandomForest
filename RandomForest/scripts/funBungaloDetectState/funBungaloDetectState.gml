function funBungaloDetectState() {
	// critical states
	var critical_state = funBungaloDetectCriticalState()
	if (critical_state != undefined) {
		return critical_state
	}
	
	// attack
	if (funBungaloWantAttack()) {
		return bungalo_states.attack
	}
	
	// move
	var fully_on_ground = funDefaultFullyOnGround()
	var new_x = self.x + sign(self.image_xscale) * self.step_xspeed
	var may_move = !place_meeting(new_x, self.y, oSolid)
	if (funBungaloSeePlayer()) {
		if (may_move and fully_on_ground) {
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