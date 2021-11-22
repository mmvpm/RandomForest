var collision_with_player = place_meeting(self.x, self.y, oPlayer)
var is_player_visible = oPlayer.image_alpha > 0 // for teleport delay
if (collision_with_player and is_player_visible and !self.is_collected) {
	self.is_collected = true
	audio_play_sound(soundCoinCollecting, 0, false)
}

// move to coin collector
if (self.is_collected) {
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
