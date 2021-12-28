function funGetStarCount(time) {
	var times = [0, 0]

	switch(funGetRoomIndex()) {
		// tutorial
		case 0:
			times = [6, 9]
			break
		case 1:
			times = [9, 20]
			break
		case 2:
			times = [8, 20]
			break
		case 3:
			times = [17, 25]
			break
		case 4:
			times = [9, 25]
			break
		case 5:
			times = [7, 17]
			break
		case 6:
			times = [7, 17]
			break
		case 7:
			times = [7, 17]
			break
		// game
		case 8:
			times = [10, 25]
			break
		case 9:
			times = [60, 120]
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