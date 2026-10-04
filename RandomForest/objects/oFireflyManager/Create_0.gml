/// Initialises the autonomous ambient firefly population.
self.target_count = 11
self.core_colour = make_color_rgb(255, 240, 176)
self.glow_colour = make_color_rgb(255, 181, 72)
self.orange_core_colour = ORANGE_FIREFLY_COLOUR
self.orange_glow_colour = ORANGE_FIREFLY_GLOW_COLOUR
self.core_scale = 0.16
self.orange_core_scale = ORANGE_FIREFLY_CORE_SCALE
self.glow_scale = 1.20 // Increase this value to make the bloom radius larger.
self.glow_alpha = 0.42 // Increase this value to make the bloom brighter.
self.orange_glow_scale_multiplier = (
	ORANGE_FIREFLY_GLOW_SCALE / self.glow_scale
)
self.orange_glow_alpha = ORANGE_FIREFLY_GLOW_ALPHA
self.sword_hit_radius = 2 // Only the firefly body is hittable, not its bloom.
self.orange_sword_hit_radius = 3
self.hit_flash_scale = 2
self.orange_hit_flash_scale = 2.75
self.death_shrink_frames = 18
self.fireflies = []
self.orange_firefly_active = false
self.spawn_timer = irandom_range(20, 90)
self.initial_count = 7
self.initialised = false
