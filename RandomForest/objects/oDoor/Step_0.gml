var all_coins_collected = not instance_exists(oCoin)
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
}