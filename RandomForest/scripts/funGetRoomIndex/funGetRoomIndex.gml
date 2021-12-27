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
		case "rLevel00":
			return 4
		case "rLevel01":
			return 5
	}
	return -1
}