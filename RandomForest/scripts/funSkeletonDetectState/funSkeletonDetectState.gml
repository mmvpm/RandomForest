function funSkeletonDetectState() {
	// critical states
	var critical_state = funSkeletonDetectCriticalState()
	if (critical_state != undefined) {
		return critical_state
	}

	if (funSkeletonWantAttack()) {
		return skeleton_states.attack
	}

	if (funSkeletonSeePlayer()) {
		return skeleton_states.react
	}

	return skeleton_states.idle
}