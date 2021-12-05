if (keyboard_check_pressed(vk_enter)) {
	if (self.current_index == 0) {
		room_goto_next()
	}
	else if (self.current_index == 1) {
		room_restart()
	}
	else if (self.current_index == 2) {
		game_end()
	}
}
else if (keyboard_check_pressed(vk_down)) {
	self.current_index += 1
	self.current_index %= self.items_count
}
else if (keyboard_check_pressed(vk_up)) {
	self.current_index += (self.items_count - 1)
	self.current_index %= self.items_count
}

if (self.alpha_animation_counter > 0) {
	--self.alpha_animation_counter
}

if (self.border_animation_counter > 0) {
	--self.border_animation_counter
}

if (self.stats_animation_counter > 0) {
	--self.stats_animation_counter
}

if (self.star_animation_counter > 0) {
	--self.star_animation_counter
	if (self.star_animation_counter == 0) {
		++self.shown_stars
		self.star_animation_counter = self.star_animation_time + self.star_animation_delay
	}
}
