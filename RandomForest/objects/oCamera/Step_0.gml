if (self.following != noone) {
	self.target_x = self.following.x
	self.target_y = self.following.y
}

var dx = self.target_x - self.x
var dy = self.target_y - self.y

var k_x = self.meeting_k_x
var k_y = self.meeting_k_y


if (abs(dx) > self.w_border || abs(dy) > self.h_border) {
	k_x = self.fast_meeting_k
	k_y = self.fast_meeting_k
}

dx /= k_x
dy /= k_y

if (abs(dx) < self.min_speed_x) {
	dx = self.target_x - self.x
	dx = sign(dx) * min(self.min_speed_x, abs(dx))
}

if (abs(dy) < self.min_speed_y) {
	dy = self.target_y - self.y
	dy = sign(dy) * min(self.min_speed_y, abs(dy))
}

self.x += dx
self.y += dy

