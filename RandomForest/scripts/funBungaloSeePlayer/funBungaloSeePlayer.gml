function funBungaloSeePlayer() {
	var is_see_player = collision_rectangle(
		self.x - sign(self.image_xscale) * self.vision_radius * 0.5,
		self.y,
		self.x + sign(self.image_xscale) * self.vision_radius, 
		self.y - 2 * self.sprite_height, oPlayer, false, false
	)
	return is_see_player
}