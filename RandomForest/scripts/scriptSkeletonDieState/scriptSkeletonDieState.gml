function funSkeletonDieStart() {
	self.sprite_index = sSkeletonDie
	self.image_index = 0
	self.die_animation_ended = false
}


function funSkeletonDieLogic() {
	funDefaultStepMove()
	
	if (self.die_animation_ended) {
		instance_destroy()
		return
	}
}