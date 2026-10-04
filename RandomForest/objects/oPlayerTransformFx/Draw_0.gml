/// Draws each fire frame alongside the same numbered body frame, without collision.
if (!instance_exists(self.owner) or self.fx_sprite == -1) exit
if (self.owner.state != player_states.stomp and self.owner.state != player_states.story_transform) exit
var frame = floor(self.owner.transform_progress)
if (frame >= sprite_get_number(self.fx_sprite)) exit
draw_sprite_ext(self.fx_sprite, frame, self.x, self.y,
	self.image_xscale, self.image_yscale, 0, c_white, self.owner.image_alpha)
