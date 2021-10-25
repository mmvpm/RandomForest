function funSlimeDetectState() {
	var critical_state = funSlimeDetectCriticalState()
	if (critical_state != undefined) {
		return critical_state
	}
	
	return slime_states.idle
}