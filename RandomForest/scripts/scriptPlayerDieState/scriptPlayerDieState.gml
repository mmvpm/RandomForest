/// Initializes the skin-specific death animation.
function funPlayerDieStart() {
	self.sprite_index = funPlayerSkinSprite(sPlayerDie)
	self.image_index = 0
	self.die_animation_ended = false
}


/// Restarts the room after the death animation finishes.
function funPlayerDieLogic() {
	funPlayerStepMove()
	
	if (self.die_animation_ended) {
		room_restart()
		return
	}
}