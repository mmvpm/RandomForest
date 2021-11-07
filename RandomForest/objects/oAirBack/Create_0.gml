self.following = oPlayer
self.x_shift = 0
self.y_shift = 0

if (self.following != noone) {
	self.x_shift = self.x - self.following.x
	self.y_shift = self.y - self.following.y
}