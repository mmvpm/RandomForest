/// Checks ground grace or the remaining airborne jump and overhead clearance.
function funPlayerNewJumpAllowed() {
	var new_jump_allowed =
		(self.coyote_buffer_counter > 0 or
		 (self.double_jump_unlocked and self.air_jump_available and !self.is_on_ground)) and
		!funPlayerCollideWithSolid(self.x, self.y + self.jump_impulse)
	return new_jump_allowed
}
