function funMenuShowControls() {
	oMenu.alpha_animation_counter = oMenu.alpha_animation_time
	var inst = instance_create_depth(0, 0, 0, oTraining)
	inst.end_function = instance_activate_all
	instance_deactivate_object(oMenu)
}

function funMenuGoPlay() {
	switch (global.current_level) {
		case 0:
			room_goto(rTutorial00)
			break
		case 1:
			room_goto(rTutorial01)
			break
		case 2:
			room_goto(rTutorial02)
			break
		case 3:
			room_goto(rTutorial03)
			break
		case 4:
			room_goto(rLevel00)
			break
		case 5:
			room_goto(rLevel01)
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