function funSlimeMoveStart() {
	self.sprite_index = sSlimeIdle
	self.image_index = 0

	self.current_direction *= -1
	if (self.current_direction != 0) {
		self.image_xscale = self.current_direction * abs(self.image_xscale)
	}
	self.current_move_distance = self.move_distance
}


function funSlimeMoveLogic() {
	var critical_state = funSlimeDetectCriticalState()
	if (critical_state != undefined) {
		funDefaultChangeState(critical_state)
		return
	}

	self.current_move_distance -= 1

	var want_move = self.current_move_distance > 0

	var imagine_x = self.x + self.sprite_width // already with right direction
	var fully_on_ground = place_meeting(imagine_x, self.y + 1, oSolid)

	var success_xmove = false
	if (want_move and fully_on_ground) {
		self.current_xspeed = self.current_direction * self.step_xspeed
	}
	else {
		self.current_xspeed = 0
	}
	success_xmove = funDefaultStepMove()

	if (!success_xmove or !want_move or !fully_on_ground) {
		funDefaultChangeState(slime_states.idle)
		return
	}
}