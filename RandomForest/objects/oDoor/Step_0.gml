// compute scale
var all_coins_collected = not instance_exists(oCoin)
self.scale += self.scale_speed
if (all_coins_collected) {
	self.is_opened = true
    self.scale_speed = self.scale_open_speed
	self.scale = min(1.0, self.scale)
}
else {
	if (self.scale > self.scale_max) {
		self.scale = self.scale_max
		self.scale_speed = -abs(self.scale_speed)
	}
	else if (self.scale < self.scale_min) {
		self.scale = self.scale_min
		self.scale_speed = abs(self.scale_speed)
	}
}

// resize
self.image_xscale = self.x_factor * self.scale
self.image_yscale = self.y_factor * self.scale

function __funPassingLevel() {
	instance_create_layer(0, 0, "UI", oLevelPassing)
}

// on collision with player
if (place_meeting(self.x, self.y, oPlayer) and self.is_opened and !self.goto_next_level) {
	self.goto_next_level = true

	// update time record with new value
	funUpdateTimeRecord(oTimeCounter.time_counter)

	// fade out effect
	oPlayer.image_alpha = 0 // for visual correct fade out
	oTimeCounter.may_count = false // stops timer
	var fade_out_effect = instance_create_depth(0, 0, -10, oFadeOut)
	fade_out_effect.end_function = __funPassingLevel
}