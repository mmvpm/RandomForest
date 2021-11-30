/// @description Go to next level

window_center()

// Load saved state
funLoadGameState()

// go to next room
if (global.is_training_completed) {
	switch (global.current_level) {
		case 0:
			room_goto(rMain)
			break
		case 1:
			room_goto(rLevel01)
			break
	}
}
else {
	room_goto(rTraining)
}