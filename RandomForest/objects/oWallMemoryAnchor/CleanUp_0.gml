/// Releases cached lettering when the anchor or room is destroyed.
if (surface_exists(self.text_surface)) surface_free(self.text_surface)
