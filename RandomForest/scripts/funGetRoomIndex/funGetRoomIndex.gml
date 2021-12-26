function funGetRoomIndex() {
	switch (room_get_name(room)) {
		case "rTutorial00":
			return 0
		case "rLevel00":
			return 1
		case "rLevel01":
			return 2
	}
	return -1
}