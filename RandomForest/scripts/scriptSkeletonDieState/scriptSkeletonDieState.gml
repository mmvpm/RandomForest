/// Disables skeleton damage, clears its sword, and starts death.
function funSkeletonDieStart() {
	funEnemyCancelAirMovement()
	self.is_dead = true
	self.can_damage_player = false
	funSkeletonAttackEnd()
	self.sprite_index = sSkeletonDie
	self.image_index = 0
	self.image_speed = 1
	self.current_xspeed = 0
	self.die_animation_ended = false
}


/// Removes the skeleton after its death animation.
function funSkeletonDieLogic() {
	funDefaultStepMove()
	
	if (self.die_animation_ended) {
		instance_destroy()
		return
	}
}
