/// Expands at ten twelve-pixel cells per second, including the final hit frame.
if (self.radius >= self.max_radius) {
    self.finish_frames += 1
    if (self.finish_frames >= 2) instance_destroy()
    return
}
self.previous_radius = self.radius
self.radius = min(self.max_radius, self.radius + 120 / game_get_speed(gamespeed_fps))
