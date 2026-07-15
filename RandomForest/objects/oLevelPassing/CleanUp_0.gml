// Release the generated level-passing surfaces when the room closes.
if (surface_exists(self.back_surf)) {
	surface_free(self.back_surf)
}
self.back_surf = noone

if (surface_exists(self.border_surf)) {
	surface_free(self.border_surf)
}
self.border_surf = noone
