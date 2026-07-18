// Release the blurred background when leaving the level selection room.
if (surface_exists(self.back_surf)) {
	surface_free(self.back_surf)
}
self.back_surf = noone
