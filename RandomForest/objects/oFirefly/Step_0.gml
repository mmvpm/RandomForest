var list = ds_list_create()
var n = collision_circle_list(self.x, self.y, self.min_r, oFirefly, false, true, list, false)

var s = 0
var dx = 0
var dy = 0
for (var i = 0; i < n; i++) {
	var inst = list[| i]
	var vec_x = inst.x - self.x
	var vec_y = inst.y - self.y
	var dist = sqrt(vec_x * vec_x + vec_y * vec_y)
	var k = self.beta * exp(-self.gamma * dist)
	s += k
	vec_x /= dist
	vec_y /= dist
	
	dx -= k * vec_x
	dy -= k * vec_y
}

ds_list_destroy(list)

if (s > 0.0) {
	dx /= s
	dy /= s
}

dx += cos(self.rot) * self.vel
dy += sin(self.rot) * self.vel

self.counter++
if (self.counter >= self.max_counter) {
	self.rot += self.rot_alpha * random_range(-1, 1)
	self.vel = random_range(self.min_v, self.max_v)
	self.counter = 0
}
self.x += dx + self.alpha * random_range(-1, 1)
self.y += dy + self.alpha * random_range(-1, 1)

self.x = clamp(self.x, 0, self.b_w)
self.y = clamp(self.y, 0, self.b_h)
