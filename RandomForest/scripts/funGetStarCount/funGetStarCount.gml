/// Returns earned stars using campaign or supplied generated-level thresholds.
function funGetStarCount(
	time,
	level_index = global.playing_level,
	level_star_times = undefined
) {
	if (time < 0) {
		return 0
	}

	var star_times = funGetLevelStarTimes(level_index, level_star_times)
	var times = [
		star_times.three_stars,
		star_times.two_stars,
	]

	var n_stars = array_length(times)
	for (var i = 0; i < n_stars; i++) {
		if (time <= times[i] * 60) {
			return n_stars + 1 - i
		}
	}

	return 1
}
