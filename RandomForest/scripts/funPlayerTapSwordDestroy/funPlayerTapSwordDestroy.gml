function funPlayerTapSwordDestroy(with_effect = true) {
	// visual effect ???
	if (with_effect) {
		var effect = instance_create_depth(
			oPlayer.x,
			oPlayer.y - abs(oPlayer.sprite_height) / 2, 
			oPlayer.depth - 1, oAirBack
		)
		effect.image_angle = darctan2(oPlayer.y - oPlayerTapSword.y, oPlayerTapSword.x - oPlayer.x)
	}
	oPlayer.has_sword = true
	instance_destroy(oPlayerTapSword)
}