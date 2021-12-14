if (self.following != noone) {
	if (instance_exists(self.following)) {
		self.x = self.following.x
		self.y = self.following.y
		self.image_xscale = self.following.image_xscale
		self.image_yscale = self.following.image_yscale
		
		switch (self.following.sprite_index) {
			case sSkeletonIdle:
				self.y -= self.image_yscale * 12
				break
			case sSkeletonHurt:
				self.y -= self.image_yscale * 12
				break
			case sSkeletonDie:
				self.y -= self.image_yscale * 12
				instance_destroy()
				break
			case sSkeletonReact:
				self.y -= self.image_yscale * 12
				break
			case sSkeletonMove:
				self.y -= self.image_yscale * 12
				break
			case sSkeletonAttack:
				var t = 0
				if (self.following.image_index <= 7.0) {
					t = self.following.image_index / 7.0
				}
				else if (self.following.image_index <= 12.0) {
					t = 1
				}
				else if (self.following.image_index <= 16.0) {
					t = 1.0 - (self.following.image_index - 12.0) / 4.0
				}
				else {
					t = 0
				}
				self.y -= self.image_yscale * 12
				self.x += self.image_xscale * lerp(0, 7, t)
				break
		}
	}
	else {
		instance_destroy()
	}
}