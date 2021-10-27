// updating counters
self.idle_countdown_counter = max(0, self.idle_countdown_counter - 1)

switch (self.state) {

	case bungalo_states.idle:
		if (self.state_changed) {
			funBungaloIdleStart()
			self.state_changed = false
		}
		funBungaloIdleLogic()
		break

	case bungalo_states.walk:
		if (self.state_changed) {
			funBungaloWalkStart()
			self.state_changed = false
		}
		funBungaloWalkLogic()
		break

	case bungalo_states.move:
		if (self.state_changed) {
			funBungaloMoveStart()
			self.state_changed = false
		}
		funBungaloMoveLogic()
		break
	
	case bungalo_states.attack:
		if (self.state_changed) {
			funBungaloAttackStart()
			self.state_changed = false
		}
		funBungaloAttackLogic()
		break
		
	case bungalo_states.hurt:
		if (self.state_changed) {
			funBungaloHurtStart()
			self.state_changed = false
		}
		funBungaloHurtLogic()
		break
	
	case bungalo_states.die:
		if (self.state_changed) {
			funBungaloDieStart()
			self.state_changed = false
		}
		funBungaloDieLogic()
		break
}