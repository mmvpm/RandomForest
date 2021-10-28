// updating counters
self.hurt_countdown_counter = max(0, self.hurt_countdown_counter - 1)

switch (self.state) {

	case skeleton_states.idle:
		if (self.state_changed) {
			funSkeletonIdleStart()
			self.state_changed = false
		}
		funSkeletonIdleLogic()
		break

	case skeleton_states.react:
		if (self.state_changed) {
			funSkeletonReactStart()
			self.state_changed = false
		}
		funSkeletonReactLogic()
		break

	case skeleton_states.move:
		if (self.state_changed) {
			funSkeletonMoveStart()
			self.state_changed = false
		}
		funSkeletonMoveLogic()
		break
	
	case skeleton_states.attack:
		if (self.state_changed) {
			funSkeletonAttackStart()
			self.state_changed = false
		}
		funSkeletonAttackLogic()
		break
		
	case skeleton_states.hurt:
		if (self.state_changed) {
			funSkeletonHurtStart()
			self.state_changed = false
		}
		funSkeletonHurtLogic()
		break
	
	case skeleton_states.die:
		if (self.state_changed) {
			funSkeletonDieStart()
			self.state_changed = false
		}
		funSkeletonDieLogic()
		break
}