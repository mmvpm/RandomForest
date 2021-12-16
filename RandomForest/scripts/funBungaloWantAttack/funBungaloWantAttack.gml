function funBungaloWantAttack() {
	var by_x = self.image_xscale * abs(sprite_get_bbox_right(sBungaloSword) - sprite_get_bbox_left(sBungaloSword))
	var by_y = self.image_yscale * abs(sprite_get_bbox_bottom(sBungaloSword) - sprite_get_bbox_top(sBungaloSword))

	var want_attack = collision_rectangle(
		self.x, self.y,
		self.x + by_x, self.y - by_y,
		oPlayer, false, false
	) != noone

	return want_attack
}