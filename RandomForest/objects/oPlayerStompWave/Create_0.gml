/// Initializes an expanding, one-hit shock front and its refraction surface.
self.radius = 0
self.previous_radius = 0
self.max_radius = 72
self.finish_frames = 0
self.hit_enemies = ds_list_create()
self.wave_surface = -1
self.size_uniform = shader_get_uniform(shStompWave, "surface_size")
self.center_uniform = shader_get_uniform(shStompWave, "wave_center")
self.radius_uniform = shader_get_uniform(shStompWave, "wave_radius")
