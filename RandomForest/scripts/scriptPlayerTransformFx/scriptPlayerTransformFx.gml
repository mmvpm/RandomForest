/// Starts the matching fire effect at the anchored feet of this action.
function funPlayerStartTransformFx() {
	funPlayerStopTransformFx()
	var fx = instance_create_depth(self.x, self.transform_ground_y, self.depth + 1, oPlayerTransformFx)
	fx.owner = self.id
	fx.fx_sprite = self.state == player_states.stomp
		? (self.is_dark ? sPlayerFxDark : sPlayerFxLight)
		: (self.transform_target_dark ? sPlayerFxLightToDark : sPlayerFxDarkToLight)
	fx.image_xscale = self.image_xscale
	fx.image_yscale = self.image_yscale
	self.transform_fx = fx
}

/// Removes the previous effect immediately on completion or interruption.
function funPlayerStopTransformFx() {
	if (instance_exists(self.transform_fx)) instance_destroy(self.transform_fx)
	self.transform_fx = noone
}
