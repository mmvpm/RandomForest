/// Initializes an editor-authored anchor without consuming randomness or player input.
self.ready = false
self.phase = "idle"
self.phase_elapsed = 0
self.seen = false
self.first_reveal = false
self.text_surface = -1
self.lines = []
self.surface_width = self.width
self.surface_height = 32
self.memory_left = self.align == "right" ? round(self.x) - self.surface_width : round(self.x)
self.memory_top = round(self.y)
self.theme = "day"
self.size_uniform = shader_get_uniform(shWallMemoryReveal, "cache_size")
self.reveal_uniform = shader_get_uniform(shWallMemoryReveal, "reveal_progress")
self.seed_uniform = shader_get_uniform(shWallMemoryReveal, "reveal_seed")
