function funMenuShowControls() {
	oMenu.alpha_animation_counter = oMenu.alpha_animation_time
	var inst = instance_create_depth(0, 0, 0, oTraining)
	inst.end_function = instance_activate_all
	instance_deactivate_object(oMenu)
}

function funMenuGoPlay() {
	audio_stop_sound(musicMenu)
	audio_play_sound(musicGame, 0, true)

	switch (global.current_level) {
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

function funMenuResetLevelsAndGo() {
	funResetLevels()
	funMenuGoPlay()
}

function funMenuExit() {
	game_end()
}