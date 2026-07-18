// Shows the controls overlay without leaving the main menu.
function funMenuShowControls() {
	oMenu.alpha_animation_counter = oMenu.alpha_animation_time
	var inst = instance_create_depth(0, 0, 0, oTraining)
	inst.end_function = instance_activate_all
	instance_deactivate_object(oMenu)
}

// Opens the level selection screen and keeps the menu music playing.
function funMenuOpenLevelSelect() {
	room_goto(rLevelSelect)
}

// Starts the requested level or the furthest unlocked level by default.
function funMenuGoPlay(level_index = global.current_level) {
	audio_stop_sound(musicMenu)
	audio_play_sound(musicGame, 0, true)

	switch (level_index) {
		case 0:
			room_goto(rTutorial01)
			break
		case 1:
			room_goto(rTutorial02)
			break
		case 2:
			room_goto(rTutorial03)
			break
		case 3:
			room_goto(rTutorial04)
			break
		case 4:
			room_goto(rTutorial05)
			break
		case 5:
			room_goto(rTutorial06)
			break
		case 6:
			room_goto(rLevel01)
			break
		case 7:
			room_goto(rLevel02)
			break
		case 8:
			room_goto(rLevel03)
			break
		case 9:
			room_goto(rLevel04)
			break
	}
}

// Resets progress and immediately starts the first level.
function funMenuResetLevelsAndGo() {
	funResetLevels()
	funMenuGoPlay()
}

// Closes the game from the main menu.
function funMenuExit() {
	game_end()
}
