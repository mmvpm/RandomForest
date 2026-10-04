/// Advances one autonomous firefly at the requested simulation speed.
function funFireflyUpdate(firefly, time_scale = 1) {
	firefly.target_timer -= time_scale
	if (firefly.target_timer <= 0) {
		funFireflyChooseTarget(firefly)
	}

	var steering_amount = 0.04 * time_scale
	firefly.vx = lerp(firefly.vx, firefly.target_vx, steering_amount)
	firefly.vy = lerp(firefly.vy, firefly.target_vy, steering_amount)

	// A small perpendicular oscillation keeps the path lively without random jitter.
	var move_angle = point_direction(0, 0, firefly.vx, firefly.vy)
	var side_speed = sin(firefly.drift_phase) * firefly.drift_strength
	firefly.x += (
		firefly.vx + lengthdir_x(side_speed, move_angle + 90)
	) * time_scale
	firefly.y += (
		firefly.vy + lengthdir_y(side_speed, move_angle + 90)
	) * time_scale
	firefly.alpha = min(
		1,
		firefly.alpha + firefly.fade_speed * time_scale
	)
	firefly.drift_phase += firefly.drift_speed * time_scale
}
