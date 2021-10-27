function funBungaloDetectState() {
	// critical states
	var critical_state = funBungaloDetectCriticalState()
	if (critical_state != undefined) {
		return critical_state
	}
	
	if (funBungaloWantAttack()) {
		return bungalo_states.attack
	}
	
	if (funBungaloSeePlayer()) {
		return bungalo_states.move
	}
	if (self.idle_countdown_counter == 0) {
		return bungalo_states.walk
	}

	return bungalo_states.idle
}