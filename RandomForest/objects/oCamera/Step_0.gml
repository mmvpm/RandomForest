if (self.following != noone) {
	self.target_x = self.following.x
	self.target_y = self.following.y
}

var dx = self.target_x - self.x
var dy = self.target_y - self.y

var k = self.meeting_k

if (abs(dx) > self.w_border || abs(dy) > self.h_border) {
	k = self.fast_meeting_k
}

self.x += dx / k
self.y += dy / k

