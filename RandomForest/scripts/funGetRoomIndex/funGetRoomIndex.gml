function funGetRoomIndex() {
	switch (room_get_name(room)) {
		case "rTutorial00":
			return 0
		case "rTutorial01":
			return 1
		case "rTutorial02":
			return 2
		case "rLevel00":
			return 3
		case "rLevel01":
			return 4
	}
	return -1
}