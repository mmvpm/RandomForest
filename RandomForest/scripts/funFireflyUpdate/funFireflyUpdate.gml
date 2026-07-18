/// Advances one autonomous firefly without referring to the player or camera.
function funFireflyUpdate(firefly) {
	firefly.target_timer--
	if (firefly.target_timer <= 0) {
		funFireflyChooseTarget(firefly)
	}

	firefly.vx = lerp(firefly.vx, firefly.target_vx, 0.04)
	firefly.vy = lerp(firefly.vy, firefly.target_vy, 0.04)

	// A small perpendicular oscillation keeps the path lively without random jitter.
	var move_angle = point_direction(0, 0, firefly.vx, firefly.vy)
	var side_speed = sin(firefly.drift_phase) * firefly.drift_strength
	firefly.x += firefly.vx + lengthdir_x(side_speed, move_angle + 90)
	firefly.y += firefly.vy + lengthdir_y(side_speed, move_angle + 90)
	firefly.alpha = min(1, firefly.alpha + firefly.fade_speed)
	firefly.drift_phase += firefly.drift_speed
}
