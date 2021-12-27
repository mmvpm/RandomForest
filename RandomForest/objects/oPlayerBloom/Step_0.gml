if (self.following != noone) {
	if (instance_exists(self.following)) {
		self.x = self.following.x
		self.y = self.following.y
		self.image_xscale = self.following.image_xscale
		self.image_yscale = self.following.image_yscale

		// bloom when player may spawn tap-sword
		/*var may_tap_attack =
			self.following.tap_attack_allowed and
			self.following.sword_destroyed and
			self.following.tap_attack_countdown_counter == 0
		if (may_tap_attack) {
			self.image_alpha = self.following.image_alpha
		}
		else {
			self.image_alpha = 0
		}*/
		self.image_alpha = min(0.6, self.following.image_alpha)

		switch (self.following.sprite_index) {
			case sPlayerDie:
				self.y -= 8 * self.image_yscale
				instance_destroy()
				break
			case sPlayerFall:
				self.y -= 14 * self.image_yscale
				break
			case sPlayerAttack1:
				self.y -= 8 * self.image_yscale
				var t = 0
				if (self.following.image_index < 1.0) {
					t = self.following.image_index
				}
				else {
					t = 1
				}
				t = power(t, 5.0)
				self.x += lerp(0, 6, t) * self.image_xscale
				break
			case sPlayerAttack2:
				self.y -= 8 * self.image_yscale
				var t = self.following.image_index / 10.0
				t = 1 - power(1 - t, 5)
				self.x += lerp(6, 3, t) * self.image_xscale
				break
			case sPlayerAttack3:
				self.y -= 8 * self.image_yscale
				self.x += 3 * self.image_xscale
				break
			default:
				self.y -= 8 * self.image_yscale
				break
		}
		
	}
	else {
		instance_destroy()
	}
}