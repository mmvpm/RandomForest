/// Draws steady firefly bodies inside a warm radial bloom.
if (!self.initialised) {
	// Draw sees the final camera rectangle used for the first visible frame.
	var cam = view_camera[0]
	var cam_x = camera_get_view_x(cam)
	var cam_y = camera_get_view_y(cam)
	var cam_w = camera_get_view_width(cam)
	var cam_h = camera_get_view_height(cam)
	var initial_orange_index = -1
	var can_spawn_orange = (
		!global.orange_firefly_records[global.playing_level]
		and random(1) < ORANGE_FIREFLY_SPAWN_CHANCE
	)
	if (can_spawn_orange) {
		// The initial batch gets one roll, not seven independent rolls.
		initial_orange_index = irandom(self.initial_count - 1)
		self.orange_firefly_active = true
	}

	for (var initial_index = 0; initial_index < self.initial_count; initial_index++) {
		array_push(
			self.fireflies,
			funFireflyCreate(
				cam_x,
				cam_y,
				cam_w,
				cam_h,
				true,
				initial_index == initial_orange_index
			)
		)
	}
	self.initialised = true
}

gpu_set_blendmode(bm_add)
for (var i = 0; i < array_length(self.fireflies); i++) {
	var firefly = self.fireflies[i]
	var hit_flash_scale = firefly.is_orange
		? self.orange_hit_flash_scale
		: self.hit_flash_scale
	var death_alpha = firefly.is_dying
		? firefly.glow_scale_multiplier / hit_flash_scale
		: 1
	var visual_alpha = firefly.alpha * death_alpha
	var glow_scale_multiplier = firefly.is_orange
		? self.orange_glow_scale_multiplier
		: 1
	var current_glow_scale = (
		self.glow_scale
		* glow_scale_multiplier
		* firefly.glow_scale_multiplier
	)
	var glow_colour = firefly.is_orange
		? self.orange_glow_colour
		: self.glow_colour
	var glow_alpha = firefly.is_orange
		? self.orange_glow_alpha
		: self.glow_alpha

	draw_sprite_ext(
		sCoinBloom,
		0,
		firefly.x,
		firefly.y,
		current_glow_scale,
		current_glow_scale,
		0,
		glow_colour,
		visual_alpha * glow_alpha
	)

	// A sword hit removes the body instantly; only the short light flash remains.
	if (firefly.is_dying) {
		continue
	}

	if (firefly.is_orange) {
		// Normal blending keeps the special body orange over the green world.
		gpu_set_blendmode(bm_normal)
	}
	draw_sprite_ext(
		sCoinBloom,
		0,
		firefly.x,
		firefly.y,
		firefly.is_orange ? self.orange_core_scale : self.core_scale,
		firefly.is_orange ? self.orange_core_scale : self.core_scale,
		0,
		firefly.is_orange ? self.orange_core_colour : self.core_colour,
		visual_alpha * (
			firefly.is_orange ? ORANGE_FIREFLY_BODY_ALPHA : 0.8
		)
	)
	draw_set_color(
		firefly.is_orange
			? ORANGE_FIREFLY_HIGHLIGHT_COLOUR
			: c_white
	)
	draw_set_alpha(
		visual_alpha * (
			firefly.is_orange ? ORANGE_FIREFLY_HIGHLIGHT_ALPHA : 0.65
		)
	)
	draw_circle(firefly.x, firefly.y, 1, false)
	if (firefly.is_orange) {
		gpu_set_blendmode(bm_add)
	}
}
gpu_set_blendmode(bm_normal)
draw_set_alpha(1)
draw_set_color(c_white)
