/// Initializes fixed, centred lettering without consuming player input or randomness.
self.ready = false
self.phase = "idle"
self.phase_elapsed = 0
self.text_surface = -1
self.cached_revealed = -1
self.revealed = 0
self.glyph_count = 0
self.lines = []
self.line_x = []
self.surface_width = self.width
self.surface_height = 36
self.memory_left = floor(self.x - self.width / 2 + 0.5)
self.memory_top = floor(self.y - self.surface_height / 2 + 0.5)
self.read_key = ""
