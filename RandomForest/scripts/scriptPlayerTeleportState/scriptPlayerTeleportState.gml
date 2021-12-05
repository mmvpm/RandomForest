function funPlayerTeleportStart() {
	self.image_alpha = 0
	self.teleport_end_effect_created = false

	// save current state
	self.old_xspeed = self.current_xspeed
	self.old_yspeed = self.current_yspeed
	self.current_xspeed = 0
	self.current_yspeed = 0

	audio_play_sound(soundPlayerTeleport, 1, false)
}


function funPlayerTeleportLogic() {
	if (self.teleport_start_effect != undefined and // last created effect (for double tap handling)
		self.teleport_start_effect.image_index > 3 and
	   !self.teleport_end_effect_created) {

		self.teleport_end_effect =
			instance_create_depth(self.x, self.y - abs(self.sprite_height) / 2, self.depth - 1, oTeleportEnd)
		self.teleport_end_effect_created = true
	}

	if (self.teleport_end_effect != undefined and // last created effect
		self.teleport_end_effect.image_index > 3) {

		funPlayerTeleportEnd()
		var detected_state = funPlayerDetectState()
		funPlayerChangeState(detected_state)
	}
}


function funPlayerTeleportEnd() {
	self.image_alpha = 1
	self.tap_attack_countdown_counter = 0 // reset counter

	// restore saved state
	self.current_xspeed = self.old_xspeed
	self.current_yspeed = self.old_yspeed
}