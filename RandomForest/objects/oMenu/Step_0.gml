function __funGoPlay() {
	if (global.is_training_completed) {
		switch (global.current_level) {
			case 0:
				room_goto(rLevel00)
				break
			case 1:
				room_goto(rLevel01)
				break
		}
	}
	else {
		room_goto(rTraining)
	}
}

if (keyboard_check_pressed(vk_enter)) {
	if (self.current_index == 0) {
		// go to play
		__funGoPlay()
	}
	else if (self.current_index == 1) {
		// reset levels
		funResetLevels()
		__funGoPlay()
	}
	else if (self.current_index == 2) {
		// reset records
		funResetRecords()
	}
	else if (self.current_index == 3) {
		// exit
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

// counters

if (self.alpha_animation_counter > 0) {
	--self.alpha_animation_counter
}
