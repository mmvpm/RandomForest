/// Initializes the shared theme roles without changing the menu layout.
funApplyUiPresentation(funThemePresentation("day", undefined, true))
if (global.is_training_completed) {
	self.items_count = 4
	self.strings = [
		"Продолжить",
		"Справка",
		"Настройки",
		"Выйти",
	]
	self.functions = [
		funMenuOpenLevelSelect,
		funMenuShowControls,
		funMenuOpenSettings,
		funMenuExit,
	]
	self.immediate_actions = [true, true, true, false]
}
else {
	self.items_count = 4
	self.strings = [
		"Начать играть",
		"Справка",
		"Настройки",
		"Выйти",
	]
	self.functions = [
		funMenuBeginCampaign,
		funMenuShowControls,
		funMenuOpenSettings,
		funMenuExit,
	]
	self.immediate_actions = [false, true, true, false]
}



self.current_scale = 1.0
self.default_scale = 0.9

self.border_sprite = sBorder4
self.border_width = 160
self.border_height = 35

self.text_scale = 20 / 24

self.separate_dist = 40
self.top_item = 88

self.current_index = 0

// Match the page opened by Continue, including after replaying earlier levels.
funMenuBackgroundCreate(clamp(floor(global.current_level), 0, funGetLevelsCount() - 1))

// fade in
self.alpha_animation_time = 60
self.alpha_animation_counter = self.alpha_animation_time
if (variable_global_exists("skip_menu_fade_once") and global.skip_menu_fade_once) {
	self.alpha_animation_counter = 0
	global.skip_menu_fade_once = false
}

// mouse handle
self.mouse_allowed_counter = 10 // frames
self.last_mouse_x = 0
self.last_mouse_y = 0
self.x_shift_cached = 0
self.y_shift_cached = 0
self.x_left_cached = []
self.y_top_cached = []
self.x_right_cached = []
self.y_bottom_cached = []

// music
audio_stop_all()
audio_play_sound(musicMenu, 0, true)
