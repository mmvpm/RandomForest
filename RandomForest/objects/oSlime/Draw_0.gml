// Procedural jump poses affect drawing only, never the collision mask.
draw_sprite_ext(
	self.sprite_index,
	self.image_index,
	self.x,
	self.y,
	self.image_xscale * self.enemy_visual_scale_x,
	self.image_yscale * self.enemy_visual_scale_y,
	self.image_angle,
	self.image_blend,
	self.image_alpha
)
