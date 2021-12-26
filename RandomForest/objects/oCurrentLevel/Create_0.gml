var current_room = funGetRoomIndex()

if (current_room != -1) {
	global.current_level = current_room
	global.is_training_completed = true  // bullshit again :)
	funSaveGameState()
}