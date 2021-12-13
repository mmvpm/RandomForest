if (keyboard_check_pressed(vk_enter)) {
	self.functions[self.current_index]()
}
else if (keyboard_check_pressed(vk_down)) {
	self.current_index += 1
	self.current_index %= self.items_count
}
else if (keyboard_check_pressed(vk_up)) {
	self.current_index += (self.items_count - 1)
	self.current_index %= self.items_count
}

// counters
if (self.alpha_animation_counter > 0) {
	--self.alpha_animation_counter
}

// back movement
var next_x = self.back_x + self.back_speed_x
self.back_x = clamp(next_x, 0, self.back_max_x)
if (next_x != self.back_x) {
	self.back_speed_x *= -1
}

var next_y = self.back_y + self.back_speed_y
self.back_y = clamp(next_y, 0, self.back_max_y)
if (next_y != self.back_y) {
	self.back_speed_y *= -1
}
