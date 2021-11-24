function __funGenPosition(coord, radius) {
	return random_range(coord - radius, coord + radius)
}

if (self.counter_freq <= 0) {
	if (self.following != noone) {
		self.target_x = __funGenPosition(self.following.x + self.offset_x, self.radius)
		self.target_y = __funGenPosition(self.following.y + self.offset_y, self.radius)
	}
	self.counter_freq = self.freq
}

self.counter_freq--

var dx = self.target_x - self.x
var dy = self.target_y - self.y

var target_rot = darctan2(dy, dx)

var dist = sqrt(dx * dx + dy * dy)
var k = dist / self.radius
var sp = k * self.move_speed
var rt = min(k * self.rot_speed, 1.0)

self.rot = lerp(self.rot, target_rot, rt)

self.x += dcos(self.rot) * sp
self.y += dsin(self.rot) * sp
