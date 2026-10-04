/// Selects the next state and schedules its one-time initialization.
function funPlayerChangeState(new_state) {
	self.state = new_state
	self.state_changed = true
}