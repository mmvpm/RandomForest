// constants
self.min_r = 20.0
self.alpha = 0.1
self.gamma = 0.3
self.beta = 2.0
self.rot_alpha = pi / 3
self.min_v = 0.1
self.max_v = 0.5

self.max_counter = 30
self.b_w = sprite_get_width(sBackground_x13)
self.b_h = sprite_get_height(sBackground_x13)

// properties
self.rot = random_range(-pi, pi)
self.vel = random_range(self.min_v, self.max_v)
self.counter = 0
