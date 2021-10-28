function funDefaultFullyOnGround() {
	var collision_mask_width = abs(self.bbox_right - self.bbox_left)
	var imagine_x = self.x + sign(self.image_xscale) * collision_mask_width
	var fully_on_ground = place_meeting(imagine_x, self.y + 1, oSolid)
	return fully_on_ground
}