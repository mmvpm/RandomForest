/// Returns the incoming player sword whose current trajectory will hit the bungalo.
function funBungaloSeeTapSword() {
	var sword_count = instance_number(oPlayerTapSword)
	for (var i = 0; i < sword_count; ++i) {
		var sword = instance_find(oPlayerTapSword, i)
		if (sword.current_speed <= 0) {
			continue
		}

		var angle_radians = sword.current_angle * pi / 180
		var speed_x = sword.current_speed * cos(angle_radians)
		var speed_y = -sword.current_speed * sin(angle_radians)
		var future_x = sword.x + speed_x * 8
		var future_y = sword.y + speed_y * 8
		var moving_toward =
			(self.x - sword.x) * speed_x +
			(self.y - sword.y) * speed_y > 0
		if (!moving_toward) {
			continue
		}

		var predicted_hit = collision_line(
			sword.x,
			sword.y,
			future_x,
			future_y,
			self.id,
			false,
			false
		)
		if (predicted_hit != noone) {
			return sword
		}
	}

	return noone
}
