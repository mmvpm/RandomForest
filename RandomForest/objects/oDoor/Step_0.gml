var all_coins_collected = not instance_exists(oCoin)
if (all_coins_collected) {
	self.is_opened = true
}

if (place_meeting(self.x, self.y, oPlayer) and self.is_opened and !self.goto_next_level) {
	self.goto_next_level = true

	var fade_out_effect = instance_create_depth(0, 0, -10, oFadeOut)
	fade_out_effect.end_function = room_goto_next
}

if (self.goto_next_level and !instance_exists(oFadeOut)) {
	//room_goto_next()
}