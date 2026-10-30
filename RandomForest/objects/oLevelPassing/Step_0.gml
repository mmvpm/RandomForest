// Opens the next absolute level or the victory screen after the final level.
function __funContinueLevel() {
	// A replay of 00 returns to selection instead of the obsolete victory room.
	if (!funLevelTracksProgress(global.playing_level)) {
		funMenuOpenLevelSelect()
		return;
	}
	var next_index = global.playing_level + 1
	var levels_count = funGetLevelsCount()
	if (next_index < levels_count) {
		if (funStoryLevelCanEnter(next_index)) funOpenLevel(next_index)
		else funMenuOpenLevelSelect()
	}
	else {
		room_goto(rVictory)
	}
}

// Runs one selected action after the standard fade.
function __funHandleButtonAction2(button_index) { // `2` because of gms2 (you never know what...)
	var chosen_function = undefined
	switch (button_index) {
		case 0:
			chosen_function = __funContinueLevel
			break
		case 1:
			chosen_function = funRestartCurrentRun
			break
		case 2:
			function __temp() {
				audio_stop_sound(musicGame)
				room_goto(rMenu)
			}
			chosen_function = __temp
			break
	}
	if (chosen_function != undefined) {
		var fade_out_effect = instance_create_depth(0, 0, -10, oFadeOut)
		fade_out_effect.end_function = chosen_function
	}
}

/// Starts one ordered reward; every item shares the same delay and duration.
function __funStartNextRewardAnimation() {
	if (self.reward_queue_position >= array_length(self.reward_queue)) {
		self.current_reward = -1
		self.reward_animation_counter = 0
		return;
	}
	self.current_reward = self.reward_queue[self.reward_queue_position]
	++self.reward_queue_position
	self.reward_animation_counter = self.reward_interval
}

/// Returns whether result rewards are still being revealed.
function __funResultAnimationActive() {
	return self.stats_animation_counter > 0 or !self.reward_animation_started
		or self.reward_animation_counter > 0
		or self.reward_queue_position < array_length(self.reward_queue)
}

/// Immediately reveals every reward without playing a burst of collection sounds.
function __funFinishResultAnimation() {
	self.stats_animation_counter = 0
	self.reward_animation_started = true
	self.shown_stars = self.max_stars
	self.enemy_badge_t = self.enemy_clear_earned ? 1 : 0
	self.flawless_badge_t = self.flawless_earned ? 1 : 0
	self.reward_queue_position = array_length(self.reward_queue)
	self.current_reward = -1
	self.reward_animation_counter = 0
}

// Story results wait for their black-to-results fade before input or rewards.
if (instance_exists(oFadeIn)) exit

// mouse counter
if (self.mouse_allowed_counter != 0) {
	self.last_mouse_x = mouse_x - camera_get_view_x(view_camera[0])
	self.last_mouse_y = mouse_y - camera_get_view_y(view_camera[0])
}
self.mouse_allowed_counter = max(0, self.mouse_allowed_counter - 1)


if (keyboard_check_pressed(vk_enter)) {
	if (__funResultAnimationActive()) {
		__funFinishResultAnimation()
	}
	else {
		__funHandleButtonAction2(self.current_index)
	}
}
else if (mouse_check_button_pressed(mb_left)) {
	if (__funResultAnimationActive()) {
		__funFinishResultAnimation()
	}
	else {
		var new_button_index = funGetButtonByMouse(
			self.x_left_cached, self.x_right_cached,
			self.y_top_cached, self.y_bottom_cached,
			self.x_shift_cached, self.y_shift_cached,
			view_camera[0], false
		)
		if (new_button_index != -1) {
			__funHandleButtonAction2(new_button_index)
		}
	}
}
else if (keyboard_check_pressed(vk_down)) {
	self.current_index += 1
	self.current_index %= self.items_count
	audio_play_sound(soundMenuButton, 0, false)
}
else if (keyboard_check_pressed(vk_up)) {
	self.current_index += (self.items_count - 1)
	self.current_index %= self.items_count
	audio_play_sound(soundMenuButton, 0, false)
}
else if (self.mouse_allowed_counter == 0) {
	var new_button_index = funGetButtonByMouse(
		self.x_left_cached, self.x_right_cached,
		self.y_top_cached, self.y_bottom_cached,
		self.x_shift_cached, self.y_shift_cached, 
		view_camera[0], true
	)
	if (new_button_index != -1 and self.current_index != new_button_index) {
		self.current_index = new_button_index
		audio_play_sound(soundMenuButton, 0, false)
	}
}

// counters

if (self.alpha_animation_counter > 0) {
	--self.alpha_animation_counter
}

if (self.border_animation_counter > 0) {
	--self.border_animation_counter
}

if (self.stats_animation_counter > 0) {
	--self.stats_animation_counter
}

if (self.stats_animation_counter == 0 and !self.reward_animation_started) {
	self.reward_animation_started = true
	__funStartNextRewardAnimation()
}

if (self.reward_animation_counter > 0) {
	--self.reward_animation_counter
	var reward_t = clamp(1 - self.reward_animation_counter / self.reward_animation_time, 0, 1)
	if (self.current_reward == 1) self.enemy_badge_t = reward_t
	if (self.current_reward == 2) self.flawless_badge_t = reward_t
	if (self.reward_animation_counter == 0) {
		if (self.current_reward == 0) {
			++self.shown_stars
		}
		audio_play_sound(soundStarCollecting, 0, false)
		__funStartNextRewardAnimation()
	}
}
