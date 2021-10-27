function funSkeletonWantAttack() {
	var real_attack_radius = self.attack_radius * abs(self.image_xscale)
	var want_attack = collision_rectangle(
		self.x, self.y,
		self.x + sign(self.image_xscale) * real_attack_radius, 
		self.y - abs(2 * self.sprite_height), oPlayer, false, false
	)
	return want_attack
}