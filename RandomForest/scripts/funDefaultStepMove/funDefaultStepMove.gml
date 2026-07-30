/// Moves an enemy with gravity and jump-through-aware collision checks.
function funDefaultStepMove() {
	// by Y
	self.current_yspeed += self.gravitation
	if (self.current_yspeed >= 20) {
		self.current_yspeed = 20
	}

	var success_ymove = false
	var y_direction = sign(self.current_yspeed)
	for (var speed_i = abs(self.current_yspeed); speed_i > 0; --speed_i) {
		var new_y = self.y + y_direction * speed_i
		var ignore_jump_thru = y_direction < 0 or self.drop_through_counter > 0
		if (!funEnemyCollidesWithSolid(
			self.x,
			new_y,
			self.y,
			self.current_yspeed,
			ignore_jump_thru
		)) {
			success_ymove = true
			self.y = new_y
			break
		}
	}
	if (!success_ymove) {
		self.current_yspeed = 0
	}

	// by X
	var success_xmove = false
	var x_direction = sign(self.current_xspeed)
	for (var speed_i = abs(self.current_xspeed); speed_i > 0; --speed_i) {
		var new_x = self.x + x_direction * speed_i
		if (!funEnemyCollidesWithSolid(new_x, self.y, self.y, 0, false)) {
			success_xmove = true
			self.x = new_x
			break
		}
	}
	if (!success_xmove) {
		self.current_xspeed = 0
	}
	return success_xmove
}
