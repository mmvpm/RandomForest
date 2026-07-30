/// Uses existing slime frames and smooth draw-only scaling during local air movement.
function funSlimeUpdateAirVisual() {
	if (self.air_navigation_active) {
		if (!self.slime_air_visual_active) {
			self.sprite_index = sSlimeMove
			self.image_index = 1
			self.image_speed = 0
			self.slime_air_visual_active = true
		}
	}
	else if (self.slime_air_visual_active) {
		self.slime_air_visual_active = false
		self.image_speed = 1

		if (self.state == slime_states.attack) {
			self.sprite_index = sSlimeAttack
			self.image_index = 0
		}
		else if (self.state == slime_states.move) {
			self.sprite_index = sSlimeMove
			self.image_index = 0
		}

		if (self.current_yspeed == 0 and funEnemyOnGroundAt(self.x, self.y)) {
			self.slime_landing_scale_counter = 4
		}
	}

	var target_scale_x = 1
	var target_scale_y = 1
	if (self.air_navigation_active) {
		target_scale_x = self.current_yspeed < 0 ? 0.96 : 0.98
		target_scale_y = self.current_yspeed < 0 ? 1.04 : 1.02
	}
	else if (self.slime_landing_scale_counter > 0) {
		target_scale_x = 1.05
		target_scale_y = 0.95
		self.slime_landing_scale_counter -= 1
	}

	self.enemy_visual_scale_x = lerp(self.enemy_visual_scale_x, target_scale_x, 0.25)
	self.enemy_visual_scale_y = lerp(self.enemy_visual_scale_y, target_scale_y, 0.25)
}

/// Checks a full short patrol corridor without moving or turning the slime.
function funSlimeCanPatrolDirection(move_direction) {
	if (move_direction == 0) {
		return false
	}

	var left_foot_offset = self.bbox_left - self.x
	var right_foot_offset = self.bbox_right - self.x
	var foot_y = self.bbox_bottom + 1

	for (var distance_checked = 1; distance_checked <= 12; ++distance_checked) {
		var check_x = self.x + move_direction * distance_checked
		if (funEnemyCollidesWithSolid(check_x, self.y, self.y, 0, false)) {
			return false
		}
		if (funEnemyPositionIsDangerous(check_x, self.y)) {
			return false
		}

		var foot_x = check_x + (move_direction > 0 ? right_foot_offset : left_foot_offset)
		if (collision_point(foot_x, foot_y, oSolid, false, false) == noone) {
			return false
		}
	}

	return true
}

/// Selects the next alternating patrol direction only after a safe probe.
function funSlimeChoosePatrolDirection() {
	var preferred_direction = -self.current_direction
	if (preferred_direction == 0) {
		preferred_direction = 1
	}

	if (funSlimeCanPatrolDirection(preferred_direction)) {
		self.current_direction = preferred_direction
		return true
	}
	if (funSlimeCanPatrolDirection(-preferred_direction)) {
		self.current_direction = -preferred_direction
		return true
	}

	return false
}

/// Starts a safe slime patrol or hazard escape.
function funSlimeMoveStart() {
	self.sprite_index = sSlimeMove
	self.image_index = 0
	self.image_speed = 1
	self.current_xspeed = 0

	if (self.current_direction != 0) {
		self.image_xscale = self.current_direction * abs(self.image_xscale)
	}
	self.current_move_distance = self.move_distance
}


/// Moves locally without stepping into edges, traps, or a stopped sword.
function funSlimeMoveLogic() {
	if (self.air_navigation_active) {
		funEnemyApplyAirMovement()
		funDefaultStepMove()
		funEnemyFinishAirMovement()
		return
	}

	self.current_move_distance -= 1

	if (self.escape_hazard) {
		var escape_direction = funEnemyGetEscapeDirection()
		if (escape_direction == 0) {
			self.escape_hazard = false
			self.current_xspeed = 0
			funDefaultChangeState(slime_states.idle)
			return
		}
		self.current_direction = escape_direction
		self.image_xscale = escape_direction * abs(self.image_xscale)
		self.current_xspeed = escape_direction * self.step_xspeed
		funDefaultStepMove()
		if (!funEnemyPositionIsDangerous(self.x, self.y)) {
			self.escape_hazard = false
			funDefaultChangeState(slime_states.idle)
		}
		return
	}

	var detected_state = funSlimeDetectState()
	if (detected_state != undefined and detected_state != self.state) {
		funDefaultChangeState(detected_state)
		return
	}

	var want_move = self.current_move_distance > 0
	if (!want_move or !funEnemyCanWalk(self.current_direction)) {
		self.current_xspeed = 0
		funDefaultChangeState(slime_states.idle)
		return
	}

	self.current_xspeed = self.current_direction * self.step_xspeed
	funDefaultStepMove()
}
