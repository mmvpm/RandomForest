function funPlayerDieStart() {
	self.sprite_index = sPlayerDie
	self.image_index = 0
	self.die_animation_ended = false
}


function funPlayerDieLogic() {
	funPlayerStepMove()
	
	if (self.die_animation_ended) {
		room_restart()
		return
	}
}