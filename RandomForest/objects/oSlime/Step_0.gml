// lighting
if (instance_exists(self.eye_light)) {
	funGetEyePos()
	if (self.eye_x == noone) {
		instance_destroy(self.eye_light)
	} else {
		self.eye_light.x = self.x + self.eye_x
		self.eye_light.y = self.y + self.eye_y	
	}
}

if (instance_exists(self.light)) {
	self.light.x = self.x
	self.light.y = self.y - 0.5 * self.sprite_height
}

// update counters
self.cooldown_counter = max(0, self.cooldown_counter - 1)
self.idle_countdown_counter = max(0, self.idle_countdown_counter - 1)
self.hurt_countdown_counter = max(0, self.hurt_countdown_counter - 1)

switch (self.state) {

	case slime_states.idle:
		if (self.state_changed) {
			funSlimeIdleStart()
			self.state_changed = false
		}
		funSlimeIdleLogic()
		break

	case slime_states.move:
		if (self.state_changed) {
			funSlimeMoveStart()
			self.state_changed = false
		}
		funSlimeMoveLogic()
		break

	case slime_states.attack:
		if (self.state_changed) {
			funSlimeAttackStart()
			self.state_changed = false
		}
		funSlimeAttackLogic()
		break

	case slime_states.hurt:
		if (self.state_changed) {
			funSlimeHurtStart()
			self.state_changed = false
		}
		funSlimeHurtLogic()
		break

	case slime_states.die:
		if (self.state_changed) {
			funSlimeDieStart()
			self.state_changed = false
		}
		funSlimeDieLogic()
		break
}