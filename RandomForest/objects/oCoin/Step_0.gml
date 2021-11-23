var collision_with_player = place_meeting(self.x, self.y, oPlayer)
var is_player_visible = oPlayer.image_alpha > 0 // for teleport delay
if (collision_with_player and is_player_visible) {
	self.is_collected = true
}

// move to coin collector
if (self.is_collected) {
	if (instance_exists(self.inner_light)) {
		layer = layer_get_id("UI")
		instance_destroy(self.inner_light)
		instance_destroy(self.ambient_light)
	}
	
	var distance_to_collector = point_distance(
		self.x, self.y, 
		oCoinCollector.x, oCoinCollector.y
	)
	if (distance_to_collector > self.flight_speed) {
		move_towards_point(oCoinCollector.x, oCoinCollector.y, self.flight_speed)
	}
	else { // close enough
		oCoinCollector.coins_collected += 1
		instance_destroy()
	}
}
