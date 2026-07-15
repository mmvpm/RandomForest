// Release the blurred menu background when leaving the menu.
if (surface_exists(self.back_surf)) {
	surface_free(self.back_surf)
}
self.back_surf = noone
