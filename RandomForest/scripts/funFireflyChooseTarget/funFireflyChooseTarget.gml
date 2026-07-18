/// Chooses a gently curved target velocity for one wandering firefly.
function funFireflyChooseTarget(firefly) {
	var current_angle = point_direction(0, 0, firefly.vx, firefly.vy)
	var target_angle = current_angle + random_range(-110, 110)
	var target_speed = random_range(0.12, 0.48)

	firefly.target_vx = lengthdir_x(target_speed, target_angle)
	firefly.target_vy = lengthdir_y(target_speed, target_angle)
	firefly.target_timer = irandom_range(24, 90)
}
