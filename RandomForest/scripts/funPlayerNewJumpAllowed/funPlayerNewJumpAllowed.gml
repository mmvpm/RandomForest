function funPlayerNewJumpAllowed() {
	var new_jump_allowed = 
		(self.coyote_buffer_counter > 0) and 
		!funPlayerCollideWithSolid(self.x, self.y + self.jump_impulse)
	return new_jump_allowed
}