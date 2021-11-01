function funPlayerStepMove() {
	// by Y
	self.current_yspeed += self.gravitation
	if (self.current_yspeed >= 20) {
		self.current_yspeed = 20
	}

	var success_ymove = false
	var y_direction = sign(self.current_yspeed)
	for (var speed_i = abs(self.current_yspeed); speed_i > 0; --speed_i) {
		var new_y = self.y + y_direction * speed_i
		if (!funPlayerCollideWithSolid(self.x, new_y)) {
			success_ymove = true
			self.y = new_y
			break
		}
	}
	if (!success_ymove) {
		self.current_yspeed = 0
	}

	// by X
	var x_direction = sign(self.current_xspeed)
	for (var speed_i = abs(self.current_xspeed); speed_i > 0; --speed_i) {
		var new_x = self.x + x_direction * speed_i
		if (!funPlayerCollideWithSolid(new_x, self.y)) {
			self.x = new_x
			break
		}
	}

	// friction by X
	var on_ground = funPlayerCollideWithSolid(self.x, self.y + 1)
	if (on_ground) {
		self.current_xspeed *= self.xfriction
	}
}