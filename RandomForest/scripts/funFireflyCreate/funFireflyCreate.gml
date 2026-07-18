/// Creates one autonomous firefly inside the current camera rectangle.
function funFireflyCreate(cam_x, cam_y, cam_w, cam_h, is_initial) {
	var margin = 16
	var initial_angle = random(360)
	var initial_speed = random_range(0.15, 0.50)
	var firefly = {
		x: random_range(cam_x + margin, cam_x + cam_w - margin),
		y: random_range(cam_y + margin, cam_y + cam_h - margin),
		vx: lengthdir_x(initial_speed, initial_angle),
		vy: lengthdir_y(initial_speed, initial_angle),
		target_vx: 0,
		target_vy: 0,
		target_timer: irandom_range(30, 120),
		alpha: is_initial ? 1 : 0,
		fade_speed: 1 / random_range(30, 60),
		glow_scale_multiplier: 1,
		is_dying: false,
		drift_phase: random(2 * pi),
		drift_speed: random_range(0.025, 0.055),
		drift_strength: random_range(0.04, 0.12),
	}
	funFireflyChooseTarget(firefly)

	return firefly
}
