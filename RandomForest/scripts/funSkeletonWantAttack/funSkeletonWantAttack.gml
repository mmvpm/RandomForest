/// Returns whether the visible player is inside the skeleton's forward sword reach.
function funSkeletonWantAttack() {
	if (!funSkeletonSeePlayer()) {
		return false
	}
	if (abs(oPlayer.bbox_bottom - self.bbox_bottom) > 12) {
		return false
	}

	var real_attack_radius = self.attack_radius * abs(self.image_xscale)
	var want_attack = collision_rectangle(
		self.x, self.y,
		self.x + sign(self.image_xscale) * real_attack_radius, 
		self.y - abs(2 * self.sprite_height), oPlayer, false, false
	) != noone
	return want_attack
}
