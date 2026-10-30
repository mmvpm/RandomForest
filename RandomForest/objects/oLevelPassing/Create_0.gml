/// Initializes the shared theme roles without changing the menu layout.
funApplyUiPresentation(funThemePresentation(funLevelTheme(global.playing_level), undefined, true))
self.items_count = 3
self.strings = [
	"Перейти дальше",
	"Начать заново",
	"Выйти в меню",
]



self.current_scale = 1.0
self.default_scale = 0.9

self.border_sprite = sBorder4
self.border_width = 140
self.border_height = 35

self.text_scale = 20 / 24

self.separate_dist = 0.2
self.top_item = 0.3

self.current_index = 0

self.back_surf = noone

var completed_level_index = global.playing_level
var result = global.last_completion_result
if (result == undefined) {
	var completion_time = oTimeCounter.time_counter
	var stars = funGetStarCount(
		global.time_records[completed_level_index],
		completed_level_index,
		global.playing_level_star_times
	)
	result = {
		current_time: completion_time,
		best_time: global.time_records[completed_level_index],
		stars_before: stars,
		stars_after: stars,
		enemy_clear_before: global.enemy_clear_records[completed_level_index],
		enemy_clear_after: global.enemy_clear_records[completed_level_index],
		flawless_before: global.flawless_records[completed_level_index],
		flawless_after: global.flawless_records[completed_level_index],
		new_enemy_clear: false,
		new_flawless: false,
	}
}

self.current_time = result.current_time
self.best_time = result.best_time
self.star_times = funGetLevelStarTimes(
	completed_level_index,
	global.playing_level_star_times
)
self.max_stars = result.stars_after
self.shown_stars = result.stars_before
// One cadence for every newly earned star and badge (30 frames = 0.5 seconds).
self.reward_interval = 30
self.reward_animation_time = 20
self.reward_animation_counter = 0
self.reward_animation_started = false
self.reward_queue = []
self.reward_queue_position = 0
self.current_reward = -1
for (var star = result.stars_before; star < result.stars_after; ++star) {
	array_push(self.reward_queue, 0)
}
self.enemy_clear_earned = result.enemy_clear_after
self.flawless_earned = result.flawless_after
self.enemy_badge_t = result.enemy_clear_before ? 1 : 0
self.flawless_badge_t = result.flawless_before ? 1 : 0
if (result.new_enemy_clear) array_push(self.reward_queue, 1)
if (result.new_flawless) array_push(self.reward_queue, 2)

self.stats_animation_time = 60
self.stats_animation_counter = self.stats_animation_time

self.alpha_animation_time = 25
self.alpha_animation_counter = self.alpha_animation_time

self.border_animation_time = 25
self.border_animation_counter = self.border_animation_time

self.border_surf = noone

instance_deactivate_all(true)
instance_activate_object(oWeatherAudio)
instance_activate_object(oDebug)
instance_activate_object(oFullscreen)

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
