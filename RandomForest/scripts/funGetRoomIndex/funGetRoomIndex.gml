function funGetRoomIndex() {
	switch (room_get_name(room)) {
		case "rTutorial01":
			return 0
		case "rTutorial02":
			return 1
		case "rTutorial03":
			return 2
		case "rTutorial04":
			return 3
		case "rTutorial05":
			return 4
		case "rTutorial06":
			return 5
		case "rLevel01":
			return 6
		case "rLevel02":
			return 7
		case "rLevel03":
			return 8
		case "rLevel04":
			return 9
	}
	return -1
}