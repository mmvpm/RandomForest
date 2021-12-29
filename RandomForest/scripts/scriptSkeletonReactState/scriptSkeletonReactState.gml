function funSkeletonReactStart() {
	self.sprite_index = sSkeletonReact
	self.image_index = 0
	self.react_animation_ended = false
	self.current_xspeed = 0
}


function funSkeletonReactLogic() {
	var direction_to_player = oPlayer.x - self.x
	if (abs(direction_to_player) < 12) {
		direction_to_player = 0
	}
	direction_to_player = sign(direction_to_player)

	if (direction_to_player != 0) {
		self.image_xscale = direction_to_player * abs(self.image_xscale)
	}

	funDefaultStepMove()

	var critical_state = funSkeletonDetectCriticalState()
	if (critical_state != undefined) {
		funDefaultChangeState(critical_state)
		return
	}

	if (self.react_animation_ended) {
		var fully_on_ground = funDefaultFullyOnGround()
		var new_x = self.x + sign(self.image_xscale) * self.step_xspeed
		var may_move = !place_meeting(new_x, self.y, oSolid)
		var dangerous_move = place_meeting(new_x, self.y, oTrap)

		if (fully_on_ground and may_move) {
			if (!dangerous_move) {
				funDefaultChangeState(skeleton_states.move)
			}
		}
		else {
			funDefaultChangeState(skeleton_states.idle)
		}
		return
	}
}