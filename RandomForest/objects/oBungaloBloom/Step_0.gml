if (self.following != noone) {
	if (instance_exists(self.following)) {
		self.x = self.following.x
		self.y = self.following.y
		self.image_xscale = self.following.image_xscale
		self.image_yscale = self.following.image_yscale
		self.image_alpha = 0.6
		
		switch (self.following.sprite_index) {
			case sBungaloDie:
				self.y -= 10 * self.image_yscale
				instance_destroy()
				break
			case sBungaloMove:
				var t = floor(self.following.image_index % 4.0)
				switch (t) {
					case 0:
						t = 10
						break
					case 1:
						t = 15
						break
					case 2:
						t = 16
						break
					case 3:
						t = 15
						break
				}
				self.y -= t * self.image_yscale
				break
			case sBungaloIdle:
				if (self.following.image_index <= 2.5) {
					var t = self.following.image_index / 2.5
					self.y -= lerp(10, 11, t) * self.image_yscale
				}
				else {
					var t = (self.following.image_index - 2.5) / 2.5
					self.y -= lerp(11, 9, t) * self.image_yscale
				}
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