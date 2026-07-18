/// Draws steady firefly bodies inside a warm radial bloom.
if (!self.initialised) {
	// Draw sees the final camera rectangle used for the first visible frame.
	var cam = view_camera[0]
	var cam_x = camera_get_view_x(cam)
	var cam_y = camera_get_view_y(cam)
	var cam_w = camera_get_view_width(cam)
	var cam_h = camera_get_view_height(cam)

	for (var initial_index = 0; initial_index < self.initial_count; initial_index++) {
		array_push(self.fireflies, funFireflyCreate(cam_x, cam_y, cam_w, cam_h, true))
	}
	self.initialised = true
}

gpu_set_blendmode(bm_add)
for (var i = 0; i < array_length(self.fireflies); i++) {
	var firefly = self.fireflies[i]
	var death_alpha = firefly.is_dying
		? firefly.glow_scale_multiplier / self.hit_flash_scale
		: 1
	var visual_alpha = firefly.alpha * death_alpha
	var current_glow_scale = self.glow_scale * firefly.glow_scale_multiplier

	draw_sprite_ext(
		sCoinBloom,
		0,
		firefly.x,
		firefly.y,
		current_glow_scale,
		current_glow_scale,
		0,
		self.glow_colour,
		visual_alpha * self.glow_alpha
	)

	// A sword hit removes the body instantly; only the short light flash remains.
	if (firefly.is_dying) {
		continue
	}

	draw_sprite_ext(
		sCoinBloom,
		0,
		firefly.x,
		firefly.y,
		0.16,
		0.16,
		0,
		self.core_colour,
		visual_alpha * 0.8
	)
	draw_set_color(c_white)
	draw_set_alpha(visual_alpha * 0.65)
	draw_circle(firefly.x, firefly.y, 1, false)
}
gpu_set_blendmode(bm_normal)
draw_set_alpha(1)
draw_set_color(c_white)
