function funBungaloDieStart() {
	self.sprite_index = sBungaloDie
	self.image_index = 0
	self.die_animation_ended = false
}


function funBungaloDieLogic() {
	funDefaultStepMove()
	
	if (self.die_animation_ended) {
		instance_destroy()
		return
	}
}