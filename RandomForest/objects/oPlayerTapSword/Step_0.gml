// update counters
self.flight_time_counter = max(0, self.flight_time_counter - 1)
if (self.current_speed > 0 and self.flight_time_counter == 0) {
	funPlayerTapSwordDestroy()
	return
}

// update last empty place for player
if (!funPlayerCollideWithSolid(self.x, self.y + self.shift_of_player_y)) {
	self.last_empty_x = self.x
	self.last_empty_y = self.y + self.shift_of_player_y
}

// change angle
self.image_angle = self.current_angle

// no movement
if (self.current_speed == 0) {
	return
}
// now self.current_speed > 0

// current_angle
var cos_angle = cos(self.current_angle / 180 * pi)
var sin_angle = -sin(self.current_angle / 180 * pi)

// moving by X and Y together
var success_move = false
for (var speed_i = self.current_speed; speed_i > 0; --speed_i) {
	var new_x = self.x + speed_i * cos_angle
	var new_y = self.y + speed_i * sin_angle
	if (!place_meeting(new_x, new_y, oSolid)) {
		success_move = true
		self.y = new_y
		self.x = new_x
		break
	}
}
if (!success_move) {
	self.current_speed = 0
}

// collide with enemy
var nearest_enemy = instance_place(self.x, self.y, oEnemy)
if (nearest_enemy != noone) {
	var close_enough = abs(nearest_enemy.x - self.x) <= abs(self.sprite_width / 2)
	if (close_enough) {
		funPlayerTapSwordDestroy()
		return
	}
}