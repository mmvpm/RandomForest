/// Disables slime contact damage and starts its death animation.
function funSlimeDieStart() {
	funEnemyCancelAirMovement()
	self.is_dead = true
	self.can_damage_player = false
	self.sprite_index = sSlimeDie
	self.image_index = 0
	self.image_speed = 1
	self.current_xspeed = 0
	self.current_yspeed = 0
	self.die_animation_ended = false
}


/// Splits a large slime and removes it after the death animation.
function funSlimeDieLogic() {
	funDefaultStepMove()

	if (self.image_index >= 2 and !self.is_splitted) {
		var child_xscale = self.image_xscale / 2
		var child_yscale = self.image_yscale / 2
		var real_slime_height = abs(self.sprite_height * self.image_yscale)
		var new_slime_y = self.y - real_slime_height / 4

		for (var i = 0; i < 2; ++i) {
			var new_slime = instance_create_depth(self.x, new_slime_y, self.depth, oSlime)
			new_slime.image_xscale = child_xscale * (2 * i - 1)
			new_slime.image_yscale = child_yscale
			new_slime.is_splitted = true
			new_slime.hurt_ximpulse = 1
			// Small slimes start with less health; this is not combat damage.
			new_slime.health = new_slime.max_health - 1
			new_slime.future_damage = 0
			new_slime.state = slime_states.hurt
		}
		self.is_splitted = true
	}

	if (self.die_animation_ended) {		
		instance_destroy()
		return
	}
}
