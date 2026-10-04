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
		var death_flash_scale = firefly.is_orange
			? self.orange_hit_flash_scale
			: self.hit_flash_scale
		var death_shrink_speed = (
			death_flash_scale / self.death_shrink_frames
		)
		firefly.glow_scale_multiplier = max(
			0,
			firefly.glow_scale_multiplier - death_shrink_speed
		)
		if (firefly.glow_scale_multiplier == 0) {
			if (firefly.is_orange) {
				self.orange_firefly_active = false
			}
			array_delete(self.fireflies, i, 1)
		}
		continue
	}

	// Fireflies are data owned by this manager, so the sword hit is handled here.
	var sword_hit_radius = firefly.is_orange
		? self.orange_sword_hit_radius
		: self.sword_hit_radius
	var hit_by_sword = collision_circle(
		firefly.x,
		firefly.y,
		sword_hit_radius,
		oPlayerSword,
		true,
		true
	) != noone
	if (hit_by_sword) {
		firefly.is_dying = true
		firefly.alpha = 1
		firefly.glow_scale_multiplier = firefly.is_orange
			? self.orange_hit_flash_scale
			: self.hit_flash_scale
		firefly.vx = 0
		firefly.vy = 0
		if (firefly.is_orange) {
			// Orange-firefly progress is committed before the death flash ends.
			global.orange_firefly_records[global.playing_level] = true
			audio_play_sound(soundOrangeFirefly, 0, false)
			funSaveGameState()
		}
		continue
	}

	funFireflyUpdate(firefly)

	if (firefly.x < cam_x or firefly.x > cam_x + cam_w or
		firefly.y < cam_y or firefly.y > cam_y + cam_h) {
		if (firefly.is_orange) {
			self.orange_firefly_active = false
		}
		array_delete(self.fireflies, i, 1)
	}
}

var current_count = array_length(self.fireflies)
if (current_count < self.target_count) {
	self.spawn_timer--
	if (self.spawn_timer <= 0) {
		var can_spawn_orange = (
			!global.orange_firefly_records[global.playing_level]
			and !self.orange_firefly_active
		)
		var spawn_orange = (
			can_spawn_orange
			and random(1) < ORANGE_FIREFLY_SPAWN_CHANCE
		)
		array_push(
			self.fireflies,
			funFireflyCreate(
				cam_x,
				cam_y,
				cam_w,
				cam_h,
				false,
				spawn_orange
			)
		)
		if (spawn_orange) {
			self.orange_firefly_active = true
		}

		// Larger deficits shorten the random wait without spawning a batch at once.
		var deficit = max(1, self.target_count - array_length(self.fireflies))
		self.spawn_timer = max(8, round(random_range(20, 90) / deficit))
	}
}
