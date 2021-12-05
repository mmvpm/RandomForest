function funGetStarCount(time) {
	var times = [0, 0, 0]
	
	switch(funGetRoomIndex()) {
		case 0:
			times = [6, 25, 80]
			break
		case 1:
			times = [40, 100, 250]
			break
	}
	
	for (var i = 0; i < 3; i++) {
		if (time <= times[i] * 60) {
			return 3 - i
		}
	}
	
	return 0
}