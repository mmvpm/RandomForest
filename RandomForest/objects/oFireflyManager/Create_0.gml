/// Initialises the autonomous ambient firefly population.
self.target_count = 11
self.core_colour = make_color_rgb(255, 240, 176)
self.glow_colour = make_color_rgb(255, 181, 72)
self.glow_scale = 1.20 // Increase this value to make the bloom radius larger.
self.glow_alpha = 0.42 // Increase this value to make the bloom brighter.
self.sword_hit_radius = 2 // Only the firefly body is hittable, not its bloom.
self.hit_flash_scale = 2
self.death_shrink_frames = 18
self.death_shrink_speed = self.hit_flash_scale / self.death_shrink_frames
self.fireflies = []
self.spawn_timer = irandom_range(20, 90)
self.initial_count = 7
self.initialised = false
