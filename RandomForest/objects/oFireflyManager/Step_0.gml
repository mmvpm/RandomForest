/// Updates, culls and gradually replenishes the ambient population.
if (!self.initialised) {
	return
}

var cam = view_camera[0]
var cam_x = camera_get_view_x(cam)
var cam_y = camera_get_view_y(cam)
var cam_w = camera_get_view_width(cam)
var cam_h = camera_get_view_height(cam)

for (var i = array_length(self.fireflies) - 1; i >= 0; i--) {
	var firefly = self.fireflies[i]

	if (firefly.is_dying) {
		firefly.glow_scale_multiplier = max(
			0,
			firefly.glow_scale_multiplier - self.death_shrink_speed
		)
		if (firefly.glow_scale_multiplier == 0) {
			array_delete(self.fireflies, i, 1)
		}
		continue
	}

	// Fireflies are data owned by this manager, so the sword hit is handled here.
	var hit_by_sword = collision_circle(
		firefly.x,
		firefly.y,
		self.sword_hit_radius,
		oPlayerSword,
		true,
		true
	) != noone
	if (hit_by_sword) {
		firefly.is_dying = true
		firefly.alpha = 1
		firefly.glow_scale_multiplier = self.hit_flash_scale
		firefly.vx = 0
		firefly.vy = 0
		continue
	}

	funFireflyUpdate(firefly)

	if (firefly.x < cam_x or firefly.x > cam_x + cam_w or
		firefly.y < cam_y or firefly.y > cam_y + cam_h) {
		array_delete(self.fireflies, i, 1)
	}
}

var current_count = array_length(self.fireflies)
if (current_count < self.target_count) {
	self.spawn_timer--
	if (self.spawn_timer <= 0) {
		array_push(self.fireflies, funFireflyCreate(cam_x, cam_y, cam_w, cam_h, false))

		// Larger deficits shorten the random wait without spawning a batch at once.
		var deficit = max(1, self.target_count - array_length(self.fireflies))
		self.spawn_timer = max(8, round(random_range(20, 90) / deficit))
	}
}
