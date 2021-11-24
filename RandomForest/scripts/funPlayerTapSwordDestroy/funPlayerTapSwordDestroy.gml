function funPlayerTapSwordDestroy(with_effect = true) {
	if (with_effect) {
		var h2 = abs(oPlayer.sprite_height) / 2
		var player_r = 10
		var dy = oPlayer.y - h2 - oPlayerTapSword.y
		var dx = oPlayerTapSword.x - oPlayer.x
		if (dy * dy + dx * dx > player_r * player_r) {
			var angle = darctan2(dy, dx)
			var player_effect = instance_create_depth(
				oPlayer.x + player_r * dcos(angle),
				oPlayer.y - h2 - player_r * dsin(angle),
				oPlayer.depth - 1, oAirBack
			)
			player_effect.image_angle = angle

			var tap_effect = instance_create_depth(
				oPlayerTapSword.x, oPlayerTapSword.y, 
				oPlayerTapSword.depth - 1, oTapDestroy
			)
			tap_effect.image_xscale = 0.7
			tap_effect.image_yscale = 0.7
			tap_effect.image_angle = oPlayerTapSword.image_angle
			
			audio_play_sound(soundTapSwordReturn, 1, false)
		}
	}
	oPlayer.has_sword = true
	instance_destroy(oPlayerTapSword)
}