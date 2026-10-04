/// Initializes a stationary animation for the current skin.
function funPlayerIdleStart() {
	self.sprite_index = funPlayerSkinSprite(sPlayerIdle)
	self.image_index = 0
	self.current_xspeed = 0
	self.current_yspeed = 0
	self.idle_animation_ended = true
}


/// Selects idle variations and checks the next player action.
function funPlayerIdleLogic() {
	if (self.idle_animation_ended) {
		var animation_oracle = irandom(100 * 60 - 1) // 0..99 * 60 fps
		
		if (animation_oracle < self.blink_probability) {
			self.sprite_index = funPlayerSkinSprite(sPlayerBlink)
			self.idle_animation_ended = false
		}
		else if (animation_oracle < self.blink_probability + self.wondering_probability) {
			self.sprite_index = funPlayerSkinSprite(sPlayerWondering)
			self.idle_animation_ended = false
		}
		else {
			self.sprite_index = funPlayerSkinSprite(sPlayerIdle)
		}
		
		self.image_index = 0
	}
	
	var detected_state = funPlayerDetectState()
	if (detected_state != player_states.idle) {
		funPlayerChangeState(detected_state)
	}
}