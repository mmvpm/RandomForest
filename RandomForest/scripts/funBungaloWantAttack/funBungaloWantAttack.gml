function funBungaloWantAttack() {
	var by_x = self.image_xscale * self.attack_radius // not |bbox_right - bbox_left| just because
	var by_y = self.image_yscale * abs(sprite_get_bbox_bottom(sBungaloSword) - sprite_get_bbox_top(sBungaloSword))

	var want_attack = collision_rectangle(
		self.x, self.y,
		self.x + by_x, self.y - by_y,
		oPlayer, false, false
	) != noone

	return want_attack
}