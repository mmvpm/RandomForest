// returns true if operation was successful

function funPlayerTapToEmptyPlace() {
	var max_radius = 12 // search radius in pixels
	var success_tap = false // result

	// initial search position
	var tap_sword_x = oPlayerTapSword.x
	var tap_sword_y = oPlayerTapSword.y + oPlayerTapSword.shift_of_player_y

	// new player position
	var new_x = 0, new_y = 0

	// find min radius
	for (var radius = 0; radius <= max_radius; ++radius) {

		// find right direction
		for (var dx = -1; dx <= 1; ++dx) {
			for (var dy = -1; dy <= 1; ++dy) {
				if (radius == 0 and (dx != 0 or dy != 0)) {
					continue // only one check for radius == 0
				}
				if (radius != 0 and dx == 0 and dy == 0) {
					continue // redundant check
				}

				// next position
				var c_new_x = tap_sword_x + radius * dx
				var c_new_y = tap_sword_y + radius * dy

				// check it
				if (!funPlayerCollideWithSolid(c_new_x, c_new_y)) {
					new_x = c_new_x
					new_y = c_new_y
					success_tap = true
					break
				}
			}
			if (success_tap) break
		}
		if (success_tap) break
	}

	// no empty place around tap-sword
	if (!success_tap) {
		new_x = oPlayerTapSword.last_empty_x
		new_y = oPlayerTapSword.last_empty_y
		success_tap = true
	}

	// tap to sword
	self.x = new_x
	self.y = new_y

	return success_tap
}