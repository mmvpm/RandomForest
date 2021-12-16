if (self.following != noone) {
	if (instance_exists(self.following)) {
		self.x = self.following.x
		self.y = self.following.y
		
		var max_xscale = 1.1
		var min_xscale = 0.9
		var max_yscale = 1.1
		var min_yscale = 0.9
		
		if (self.following.image_index <= 5.0) {
			self.image_xscale = 1.0
			self.image_yscale = 1.0
		}
		else if (self.following.image_index <= 6.0) {
			self.image_xscale = lerp(1.0, min_xscale, self.following.image_index - 5.0)
			self.image_yscale = lerp(1.0, max_yscale, self.following.image_index - 5.0)
		}
		else if (self.following.image_index <= 9.0) {
			self.image_xscale = min_xscale
			self.image_yscale = max_yscale
		}
		else if (self.following.image_index <= 12.0) {
			self.image_xscale = lerp(min_xscale, max_xscale, (self.following.image_index - 9.0) / 3.0)
			self.image_yscale = lerp(max_yscale, min_yscale, (self.following.image_index - 9.0) / 3.0)
		}
		else if (self.following.image_index <= 15.0) {
			self.image_xscale = max_xscale
			self.image_yscale = min_yscale
		}
		else {
			self.image_xscale = lerp(max_xscale, 1.0, (self.following.image_index - 15.0) / 2.0)
			self.image_yscale = lerp(min_yscale, 1.0, (self.following.image_index - 15.0) / 2.0)
		}
 	}
	else {
		instance_destroy()
	}
}