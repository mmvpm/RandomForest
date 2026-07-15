/// @description Raise, settle and fade the damage number.

self.age += 1

var life_progress = min(1, self.age / self.life_time)
var rise_progress = 1 - power(1 - life_progress, 3)
self.y = self.start_y - self.rise_distance * rise_progress

var animation_scale = 1
if (self.age <= self.pop_end) {
	animation_scale = lerp(0.75, 1.1, self.age / self.pop_end)
}
else if (self.age <= self.settle_end) {
	var settle_progress = (self.age - self.pop_end) / (self.settle_end - self.pop_end)
	animation_scale = lerp(1.1, 1, settle_progress)
}
self.current_scale = self.base_scale * animation_scale

if (self.age > self.fade_start) {
	var fade_progress = (self.age - self.fade_start) / (self.life_time - self.fade_start)
	var smooth_fade = fade_progress * fade_progress * (3 - 2 * fade_progress)
	self.current_alpha = 1 - smooth_fade
}

if (self.age >= self.life_time) {
	instance_destroy()
}
