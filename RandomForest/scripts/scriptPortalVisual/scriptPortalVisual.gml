/// Initializes the shared portal pulse and its visual follower.
function funInitPortalVisual() {
	self.scale = 0
	self.scale_open_speed = 0.05
	self.scale_speed = 0.005
	self.scale_min = 0.3
	self.scale_max = 0.4
	self.x_factor = self.image_xscale
	self.y_factor = self.image_yscale
	var bloom = instance_create_layer(self.x, self.y, "Bloom", oPortalBloom)
	bloom.following = self
}

/// Animates a portal; its owner independently decides when passage is allowed.
function funUpdatePortalVisual(opened) {
	self.scale += self.scale_speed
	if (opened) {
		self.scale_speed = self.scale_open_speed
		self.scale = min(1.0, self.scale)
	}
	else if (self.scale > self.scale_max) {
		self.scale = self.scale_max
		self.scale_speed = -abs(self.scale_speed)
	}
	else if (self.scale < self.scale_min) {
		self.scale = self.scale_min
		self.scale_speed = abs(self.scale_speed)
	}
	self.image_xscale = self.x_factor * self.scale
	self.image_yscale = self.y_factor * self.scale
}
