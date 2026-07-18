var current_room = funGetRoomIndex()

if (current_room != -1) {
	// Replaying an earlier level must not lock later unlocked levels again.
	global.current_level = max(global.current_level, current_room)
	global.is_training_completed = true  // bullshit again :)
	funSaveGameState()
}
