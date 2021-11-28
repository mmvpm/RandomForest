var all_coins_collected = not instance_exists(oCoin)
self.scale += self.scale_speed
if (all_coins_collected) {
	if (!self.is_opened) {
		funCreateLight(
			self.x + 0.5 * self.sprite_width, 
			self.y - 0.8 * self.sprite_height, 
			oDoorLight
		)
		funCreateLight(
			self.x + 0.5 * self.sprite_width, 
			self.y - 0.2 * self.sprite_height, 
			oDoorLight
		)
	}
	self.is_opened = true
	self.scale_speed = self.scale_open_speed
	self.scale = min(1.0, self.scale)
} else {
	if (self.scale > self.scale_max) {
		self.scale = self.scale_max
		self.scale_speed = -abs(self.scale_speed)
	} else if (self.scale < self.scale_min) {
		self.scale = self.scale_min
		self.scale_speed = abs(self.scale_speed)
	}
}

self.image_xscale = self.x_factor * self.scale
self.image_yscale = self.y_factor * self.scale
