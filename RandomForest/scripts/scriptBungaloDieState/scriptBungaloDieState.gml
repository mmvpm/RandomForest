/// Disables bungalo damage, clears its sword, and starts death.
function funBungaloDieStart() {
	funEnemyCancelAirMovement()
	self.is_dead = true
	self.can_damage_player = false
	funBungaloAttackEnd()
	self.sprite_index = sBungaloDie
	self.image_index = 0
	self.die_animation_ended = false
}


/// Removes the bungalo after its death animation.
function funBungaloDieLogic() {
	funDefaultStepMove()
	
	if (self.die_animation_ended) {
		instance_destroy()
		return
	}
}
