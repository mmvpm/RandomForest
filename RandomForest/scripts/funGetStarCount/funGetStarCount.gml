function funGetStarCount(time) {
	var times = [0, 0]

	switch(funGetRoomIndex()) {
		case 0:
			times = [8, 25]
			break
		case 1:
			times = [45, 120]
			break
	}

	for (var i = 0; i < 2; i++) {
		if (time <= times[i] * 60) {
			return 3 - i
		}
	}

	return 1
}