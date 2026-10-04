/// Opens the gameplay portal once every berry is collected.
self.is_opened = !instance_exists(oCoin)
funUpdatePortalVisual(self.is_opened)

// Saves the record and unlocks the next level in the shared sequence.
function __funCompleteLevel() {
	var level_index = global.playing_level
	var levels_count = funGetLevelsCount()
	var completion_time = oTimeCounter.time_counter
	var star_times = funGetLevelStarTimes(
		level_index,
		global.playing_level_star_times
	)
	var page_index = level_index div LEVEL_SELECT_PAGE_SIZE
	var page_star_times = array_create(levels_count, undefined)
	var first_page_level = page_index * LEVEL_SELECT_PAGE_SIZE
	var last_page_level = min(
		first_page_level + LEVEL_SELECT_PAGE_SIZE,
		levels_count
	)
	for (
		var page_level = first_page_level;
		page_level < last_page_level;
		++page_level
	) {
		page_star_times[page_level] = funGetLevelStarTimes(
			page_level,
			page_level == level_index ? star_times : undefined
		)
	}
	var page_before = funGetAchievementPageProgress(
		page_index,
		LEVEL_SELECT_PAGE_SIZE,
		page_star_times
	)

	var stars_before = funGetStarCount(
		global.time_records[level_index],
		level_index,
		star_times
	)
	var enemy_clear_before = global.enemy_clear_records[level_index]
	var flawless_before = global.flawless_records[level_index]
	var enemy_clear_run = funAreAllCombatEnemiesDefeated()
	var flawless_run = (
		variable_global_exists("current_run_flawless")
		and global.current_run_flawless
	)

	funUpdateTimeRecord(completion_time, level_index)
	global.enemy_clear_records[level_index] = (
		enemy_clear_before or enemy_clear_run
	)
	global.flawless_records[level_index] = (
		flawless_before or flawless_run
	)

	var stars_after = funGetStarCount(
		global.time_records[level_index],
		level_index,
		star_times
	)
	var page_after = funGetAchievementPageProgress(
		page_index,
		LEVEL_SELECT_PAGE_SIZE,
		page_star_times
	)
	if (!page_before.is_complete and page_after.is_complete) {
		global.pending_completed_page = page_index
	}

	global.last_completion_result = {
		level_index: level_index,
		current_time: completion_time,
		best_time: global.time_records[level_index],
		stars_before: stars_before,
		stars_after: stars_after,
		enemy_clear_before: enemy_clear_before,
		enemy_clear_after: global.enemy_clear_records[level_index],
		flawless_before: flawless_before,
		flawless_after: global.flawless_records[level_index],
		new_enemy_clear: !enemy_clear_before and enemy_clear_run,
		new_flawless: !flawless_before and flawless_run,
	}

	global.current_level = max(
		global.current_level,
		min(level_index + 1, levels_count - 1)
	)
	if (level_index == levels_count - 1) {
		global.is_game_finished = true
	}
	funSaveGameState()
}

// on collision with player	
if (place_meeting(self.x, self.y, oPlayer) and self.is_opened and !self.goto_next_level) {
	self.goto_next_level = true

	// fade out effect
	oPlayer.image_alpha = 0 // for visual correct fade out
	oTimeCounter.may_count = false // stops timer
	var fade_out_effect = instance_create_depth(0, 0, -10, oFadeOut)
	__funCompleteLevel()
	fade_out_effect.end_function = funShowCompletedLevel
}
