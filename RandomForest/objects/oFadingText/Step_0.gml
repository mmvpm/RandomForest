if (self.tick_counter >= self.active_time) { // fading part
	// fading_time = 60 and text_alpha_max = 0.9 for comments
	self.text_alpha_current =
		(1 -
			sin(
				(self.tick_counter - self.active_time) // [0, 60]
				* pi / 2 / self.fading_time            // [0, pi / 2]
			)                                          // [0, 1]
		)                                              // [1, 0]
		* self.text_alpha_max                          // [0.9, 0]
		
}

if (self.tick_counter >= self.active_time + self.fading_time) {
	instance_destroy()
}

// update time
self.tick_counter += 1