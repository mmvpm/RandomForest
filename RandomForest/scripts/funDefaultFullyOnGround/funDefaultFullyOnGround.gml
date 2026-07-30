/// Returns whether the leading foot is supported for the current facing.
function funDefaultFullyOnGround() {
	return funEnemyHasGroundAhead(sign(self.image_xscale), self.step_xspeed)
}
