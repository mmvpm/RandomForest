#macro LEVEL_SELECT_PAGE_SIZE 10

/// Returns aggregate achievement progress for one level-select page.
function funGetAchievementPageProgress(
	page_index,
	page_size,
	level_star_times = undefined
) {
	var levels_count = funGetLevelsCount()
	var first_level = page_index * page_size
	var levels_on_page = max(0, min(page_size, levels_count - first_level))
	var earned_stars = 0
	var earned_enemy_clears = 0
	var earned_flawless = 0

	for (var offset = 0; offset < levels_on_page; ++offset) {
		var level_index = first_level + offset
		var star_times = undefined
		if (
			is_array(level_star_times)
			and level_index < array_length(level_star_times)
		) {
			star_times = level_star_times[level_index]
		}
		star_times = funGetLevelStarTimes(level_index, star_times)
		earned_stars += funGetStarCount(
			global.time_records[level_index],
			level_index,
			star_times
		)
		earned_enemy_clears += global.enemy_clear_records[level_index]
		earned_flawless += global.flawless_records[level_index]
	}

	var max_stars = levels_on_page * 3
	return {
		first_level: first_level,
		levels_count: levels_on_page,
		earned_stars: earned_stars,
		max_stars: max_stars,
		earned_enemy_clears: earned_enemy_clears,
		earned_flawless: earned_flawless,
		is_complete: (
			levels_on_page > 0
			and earned_stars == max_stars
			and earned_enemy_clears == levels_on_page
			and earned_flawless == levels_on_page
		)
	}
}
