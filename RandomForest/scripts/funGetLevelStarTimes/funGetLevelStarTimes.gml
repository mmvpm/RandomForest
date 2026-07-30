/// Returns the two time thresholds for one absolute level index.
function funGetLevelStarTimes(level_index, supplied_times = undefined) {
	if (supplied_times != undefined) {
		return supplied_times
	}

	switch (level_index) {
		case 0: return { three_stars: 6, two_stars: 9 }
		case 1: return { three_stars: 9, two_stars: 20 }
		case 2: return { three_stars: 8, two_stars: 20 }
		case 3: return { three_stars: 17, two_stars: 25 }
		case 4: return { three_stars: 9, two_stars: 25 }
		case 5: return { three_stars: 7, two_stars: 17 }
		case 6: return { three_stars: 10, two_stars: 25 }
		case 7: return { three_stars: 7, two_stars: 19 }
		case 8: return { three_stars: 7, two_stars: 18 }
		case 9: return { three_stars: 60, two_stars: 120 }
	}

	var catalog = funLoadChallengeCatalog()
	var generated_index = level_index - CAMPAIGN_LEVELS_COUNT
	if (generated_index < 0 or generated_index >= array_length(catalog.levels)) {
		return { three_stars: 0, two_stars: 0 }
	}

	var level_data = funGenerateLevel({
		level_path: catalog.levels[generated_index]
	})
	return level_data.star_times
}
