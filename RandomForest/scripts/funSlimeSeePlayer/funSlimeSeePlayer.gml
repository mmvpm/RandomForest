function funSlimeSeePlayer() {
	var is_see_player = collision_rectangle(
		self.x, self.y,
		self.x + sign(self.image_xscale) * self.vision_radius, 
		self.y - self.sprite_height, oPlayer, false, false
	)
	return is_see_player
}