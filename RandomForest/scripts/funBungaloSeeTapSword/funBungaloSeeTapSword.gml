function funBungaloSeeTapSword() {
	var real_attack_radius = 1 * self.attack_radius * abs(self.image_xscale)
	var by_x = sign(self.image_xscale) * real_attack_radius
	var by_y =  abs(self.image_yscale) * abs(self.sprite_height)

	var see_tap_sword = collision_rectangle(
		self.x - by_x, self.y,
		self.x + by_x, self.y - by_y,
		oPlayerTapSword, false, false
	) != noone

	return see_tap_sword
}