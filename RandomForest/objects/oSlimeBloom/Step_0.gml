if (self.following != noone) {
	if (instance_exists(self.following)) {
		self.x = self.following.x
		self.y = self.following.y
		self.image_xscale = self.following.image_xscale
		self.image_yscale = self.following.image_yscale
		
		switch (self.following.sprite_index) {
			case sSlimeIdle:
				self.y -= self.image_yscale * 7
				break
			case sSlimeAttack:
				var t = 0
				if (self.following.image_index <= 1.5) {
					t = self.following.image_index / 1.5
				}
				else {
					t = (self.following.image_index - 1.5) / (5.0 - 1.5)
				}
				self.y -= self.image_yscale * lerp(7, 10, t)
				self.image_yscale *= lerp(1, 1.2, t)
				break
			case sSlimeHurt:
				var t = self.following.image_index / 3.0
				self.y -= self.image_yscale * 7
				self.x -= self.image_xscale * lerp(6, 0, t)
				break
			case sSlimeDie:
				self.y -= self.image_yscale * 7
				instance_destroy()
				break
		}
		
	}
	else {
		instance_destroy()
	}
}