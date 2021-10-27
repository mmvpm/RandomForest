function funBungaloWantAttack() {
	var want_attack = collision_rectangle(
		self.x, self.y,
		self.x + sign(self.image_xscale) * self.attack_radius, 
		self.y - 2 * self.sprite_height, oPlayer, false, false
	)
	return want_attack
}