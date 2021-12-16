if (self.following != noone) {
	if (instance_exists(self.following)) {
		self.x = self.following.x
		self.y = self.following.y
		self.image_angle = self.following.image_angle
	} else {
		instance_destroy()
	}
}