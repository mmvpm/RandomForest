function funSlimeDetectState() {
	var critical_state = funSlimeDetectCriticalState()
	if (critical_state != undefined) {
		return critical_state
	}
	
	var new_attack_allowed = self.cooldown_counter == 0
	if (funSlimeSeePlayer() and new_attack_allowed) {
		return slime_states.attack
	}
	
	if (self.idle_countdown_counter == 0) {
		return slime_states.move
	}
	
	return slime_states.idle
}