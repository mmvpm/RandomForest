function funSkeletonDetectState() {
	// attack
	var want_attack = collision_rectangle(
		self.x, self.y,
		self.x + sign(self.image_xscale) * self.attack_radius, 
		self.y - self.sprite_height, oPlayer, false, false
	)

	if (want_attack) {
		return skeleton_states.idle // attack
	}
	
	// move
	var is_see_player = collision_rectangle(
		self.x - sign(self.image_xscale) * self.vision_radius * 0.5,
		self.y,
		self.x + sign(self.image_xscale) * self.vision_radius, 
		self.y - self.sprite_height, oPlayer, false, false
	)

	if (is_see_player) {
		var direction_to_player = sign(oPlayer.x - self.x) // `<-`: -1, `->`: +1
		var imagine_x = self.x + direction_to_player * abs(self.sprite_width / 2) // collision mask width
		var fully_on_ground = place_meeting(imagine_x, self.y + 1, oSolid)

		var new_x = self.x + direction_to_player * self.step_xspeed
		var may_move = !place_meeting(new_x, self.y, oSolid)

		if (fully_on_ground and may_move) {
			return skeleton_states.move
		}
	}

	// idle
	return skeleton_states.idle
}