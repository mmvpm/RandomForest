self.image_angle = self.current_angle

if (self.current_speed == 0) {
	return
}
// now self.current_speed > 0

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