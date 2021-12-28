function funGetRoomIndex() {
	switch (room_get_name(room)) {
		case "rTutorial00":
			return 0
		case "rTutorial01":
			return 1
		case "rTutorial02":
			return 2
		case "rTutorial03":
			return 3
		case "rTutorial04":
			return 4
		case "rTutorial05":
			return 5
		case "rTutorial06":
			return 6
		case "rTutorial07":
			return 7
		case "rLevel00":
			return 8
		case "rLevel01":
			return 9
	}
	return -1
}