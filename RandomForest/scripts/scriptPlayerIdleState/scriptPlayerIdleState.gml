function funPlayerIdleStart() {
	self.current_xspeed = 0
	self.current_yspeed = 0
	self.sprite_index = sPlayerIdle
}


function funPlayerIdleLogic() {
	var detected_state = funPlayerDetectState()
	if (detected_state != player_states.idle) {
		funPlayerChangeState(detected_state)
	}
}