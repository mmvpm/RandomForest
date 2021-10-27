function funSkeletonReactStart() {
	self.sprite_index = sSkeletonReact
	self.image_index = 0
	self.react_animation_ended = false
	self.current_xspeed = 0
}


function funSkeletonReactLogic() {
	funDefaultStepMove()
	
	var critical_state = funSkeletonDetectCriticalState()
	if (critical_state != undefined) {
		funDefaultChangeState(critical_state)
		return
	}
	
	if (self.react_animation_ended) {
		funDefaultChangeState(skeleton_states.move)
		return
	}
}