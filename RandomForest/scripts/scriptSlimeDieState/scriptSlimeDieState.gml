function funSlimeDieStart() {
	self.sprite_index = sSlimeDie
	self.image_index = 0
	self.current_xspeed = 0
	self.current_yspeed = 0
	self.die_animation_ended = false
}


function funSlimeDieLogic() {
	funDefaultStepMove()

	if (self.image_index >= 2 and !self.is_splitted) {
		for (var i = 0; i < 2; ++i) {
			var real_slime_height = abs(self.sprite_height * self.image_yscale)
			var new_slime_y = self.y - real_slime_height / 4
			var new_slime = instance_create_depth(self.x, new_slime_y, self.depth, oSlime)

			with (new_slime) {
				image_xscale = self.image_xscale / 2
				image_yscale = self.image_yscale / 2
				image_xscale *= 2 * i - 1 // i = 0 to one side, i = 1 to another
				is_splitted = true // against repeating split in children
				hurt_ximpulse = 1
				future_damage = 1 // small slime has less by 1 health than the big one
				state = slime_states.hurt
			}
		}
		self.is_splitted = true
	}

	if (self.die_animation_ended) {		
		instance_destroy()
		return
	}
}