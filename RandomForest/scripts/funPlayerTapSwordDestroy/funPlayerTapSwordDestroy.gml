function funPlayerTapSwordDestroy(with_effect = true) {
	// visual effect ???
	if (with_effect) {
		var angle = darctan2(oPlayer.y - oPlayerTapSword.y, oPlayerTapSword.x - oPlayer.x)
		var r = 10
		var effect = instance_create_depth(
			oPlayer.x + r * dcos(angle),
			oPlayer.y - abs(oPlayer.sprite_height) / 2 - r * dsin(angle),
			oPlayer.depth - 1, oAirBack
		)
		effect.image_angle = angle
	}
	oPlayer.has_sword = true
	instance_destroy(oPlayerTapSword)
}