function funGetStarCount(time) {
	var times = [0, 0]

	switch(funGetRoomIndex()) {
		case 0:
			times = [7, 20]
			break
		case 1:
			times = [8, 25]
			break
		case 2:
			times = [45, 120]
			break
	}

	var n_levels = array_length(times)
	for (var i = 0; i < n_levels; i++) {
		if (time <= times[i] * 60) {
			return n_levels + 1 - i
		}
	}

	return 1
}