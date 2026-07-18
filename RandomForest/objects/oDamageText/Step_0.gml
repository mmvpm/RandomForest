/// @description Raise, settle and fade the damage number.

self.age += 1

var life_progress = min(1, self.age / self.life_time)
var rise_progress = 1 - power(1 - life_progress, 3)
var rise_offset = round(self.rise_distance * rise_progress)
self.x = round(self.x)
self.y = self.start_y - rise_offset

if (self.age > self.fade_start) {
	var fade_progress = (self.age - self.fade_start) / (self.life_time - self.fade_start)
	var smooth_fade = fade_progress * fade_progress * (3 - 2 * fade_progress)
	self.current_alpha = 1 - smooth_fade
}

if (self.age >= self.life_time) {
	instance_destroy()
}
