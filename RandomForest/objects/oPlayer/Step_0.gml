// update counters
self.cooldown_counter = max(0, self.cooldown_counter - 1)
self.hurt_countdown_counter = max(0, self.hurt_countdown_counter - 1)

self.jump_buffer_counter = max(0, self.jump_buffer_counter - 1)
self.fall_buffer_counter = max(0, self.fall_buffer_counter - 1)

self.is_on_ground = funPlayerCollideWithSolid(self.x, self.y + 1)
if (self.is_on_ground) {
	self.coyote_buffer_counter = self.coyote_buffer_max
} else {
	self.coyote_buffer_counter = max(0, self.coyote_buffer_counter - 1)
}


funReadInputs()


var tap_controller_created = funPlayerHandleTapSword()
if (tap_controller_created) {
	return // ???
}


switch (self.state) {

	case player_states.idle:
		if (self.state_changed) {
			funPlayerIdleStart()
			self.state_changed = false
		}
		funPlayerIdleLogic()
		break

	case player_states.move:
		if (self.state_changed) {
			funPlayerMoveStart()
			self.state_changed = false
		}
		funPlayerMoveLogic()
		break

	case player_states.prejump:
		if (self.state_changed) {
			funPlayerPreJumpStart()
			self.state_changed = false
		}
		funPlayerPreJumpLogic()
		break

	case player_states.jump:
		if (self.state_changed) {
			funPlayerJumpStart()
			self.state_changed = false
		}
		funPlayerJumpLogic()
		break

	case player_states.fall:
		if (self.state_changed) {
			funPlayerFallStart()
			self.state_changed = false
		}
		funPlayerFallLogic()
		break

	case player_states.attack:
		if (self.state_changed) {
			funPlayerAttackStart()
			self.state_changed = false
		}
		funPlayerAttackLogic()
		break

	case player_states.hurt:
		if (self.state_changed) {
			funPlayerHurtStart()
			self.state_changed = false
		}
		funPlayerHurtLogic()
		break

	case player_states.die:
		if (self.state_changed) {
			funPlayerDieStart()
			self.state_changed = false
		}
		funPlayerDieLogic()
		break
}