if (self.following != noone) {
	if (instance_exists(self.following)) {
		self.x = self.following.x
		self.y = self.following.y
		self.image_xscale = self.following.image_xscale
		self.image_yscale = self.following.image_yscale
		
		switch (self.following.sprite_index) {
			case sBungaloDie:
				self.y -= 10 * self.image_yscale
				instance_destroy()
				break
			case sBungaloMove:
				var t = 0
				if (self.following.image_index <= 2.5) {
					t = self.following.image_index / 2.5
				}
				else if (self.following.image_index <= 4.5) {
					t = 1 - (self.following.image_index - 2.5) / 2.0
				}
				else if (self.following.image_index <= 6.5) {
					t = (self.following.image_index - 4.5) / 2.0
				}
				else {
					t = 1 - (self.following.image_index - 6.5) / (8.0 - 6.5)
				}
				self.y -= lerp(10, 14, t) * self.image_yscale
				break
			default:
				self.y -= 10 * self.image_yscale
				break
		}
	}
	else {
		instance_destroy()
	}
}