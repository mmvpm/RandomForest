function funMenuShowControls() {
	oMenu.alpha_animation_counter = oMenu.alpha_animation_time
	var inst = instance_create_depth(0, 0, 0, oTraining)
	inst.end_function = instance_activate_all
	instance_deactivate_object(oMenu)
}

function funMenuGoPlay() {
	if (global.is_training_completed) {
		switch (global.current_level) {
			case 0:
				room_goto(rLevel00)
				break
			case 1:
				room_goto(rLevel01)
				break
		}
	}
	else {
		room_goto(rTraining)
	}
}

function funMenuResetLevelsAndGo() {
	funResetLevels()
	funMenuGoPlay()
}

function funMenuExit() {
	game_end()
}