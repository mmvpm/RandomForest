function funGetRoomIndex() {
	switch (room_get_name(room)) {
		case "rLevel00":
			return 0
		case "rLevel01":
			return 1
	}
	return -1
}