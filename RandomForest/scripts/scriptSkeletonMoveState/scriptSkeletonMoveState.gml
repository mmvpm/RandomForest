function funSkeletonMoveStart() {
	self.sprite_index = sSkeletonMove
	self.image_index = 0
	self.image_xscale = self.current_direction * abs(self.image_xscale)
}


function funSkeletonMoveLogic() {
	// critical states ?

	self.current_direction = sign(oPlayer.x - self.x) // to player

	if (self.current_direction != 0) {
		self.image_xscale = self.current_direction * abs(self.image_xscale)
		self.current_xspeed = self.step_xspeed * self.current_direction

		var imagine_x = self.x + self.sprite_width / 2 // collision mask width, already with right direction
		var fully_on_ground = place_meeting(imagine_x, self.y + 1, oSolid)
	
		if (!fully_on_ground) {
			self.current_xspeed = 0
		}
	}
	
	funDefaultStepMove()

	var detected_state = funSkeletonDetectState()
	if (detected_state != self.state) {
		funDefaultChangeState(detected_state)
		return
	}
}