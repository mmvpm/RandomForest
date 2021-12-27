function funGetRoomIndex() {
	switch (room_get_name(room)) {
		case "rTutorial00":
			return 0
		case "rTutorial01":
			return 1
		case "rLevel00":
			return 2
		case "rLevel01":
			return 3
	}
	return -1
}