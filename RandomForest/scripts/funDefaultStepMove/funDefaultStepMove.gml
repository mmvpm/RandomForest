function funDefaultStepMove() {
	// by Y
	self.current_yspeed += self.gravitation
	if (self.current_yspeed >= 20) {
		self.current_yspeed = 20
	}
	var new_y = self.y + self.current_yspeed
	if (!place_meeting(self.x, new_y, oSolid)) {
		self.y = new_y
	} else {
		for (var new_yi = self.y + 1; new_yi <= new_y; ++new_yi) {
			if (!place_meeting(self.x, new_yi, oSolid)) {
				self.y = new_yi
				break
			}
		}
		self.current_yspeed = 0
	}
	
	// by X
	var new_x = self.x + self.current_xspeed
	if (!place_meeting(new_x, self.y, oSolid)) {
		self.x = new_x
		return true
	} else {
		for (var new_xi = self.x + 1; new_xi <= new_x; ++new_xi) {
			if (!place_meeting(new_xi, self.y, oSolid)) {
				self.x = new_xi
				break
			}
		}
		self.current_xspeed = 0
		return false
	}
}