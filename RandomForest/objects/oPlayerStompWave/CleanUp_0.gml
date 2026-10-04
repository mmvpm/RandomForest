/// Releases the transient hit registry and copied world surface.
ds_list_destroy(self.hit_enemies)
if (surface_exists(self.wave_surface)) surface_free(self.wave_surface)
