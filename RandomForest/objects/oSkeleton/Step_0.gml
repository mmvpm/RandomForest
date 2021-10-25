switch (self.state) {

	case skeleton_states.idle:
		if (self.state_changed) {
			funSkeletonIdleStart()
			self.state_changed = false
		}
		funSkeletonIdleLogic()
		break

	case skeleton_states.move:
		if (self.state_changed) {
			funSkeletonMoveStart()
			self.state_changed = false
		}
		funSkeletonMoveLogic()
		break
}