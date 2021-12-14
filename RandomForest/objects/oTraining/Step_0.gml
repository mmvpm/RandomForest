function __funTrainingEndFunction() {
	instance_destroy(oTraining)
}

if (( keyboard_check_pressed(vk_anykey) or mouse_check_button_pressed(mb_any) ) and !self.end_training) {
	self.end_training = true

	var fade_out_effect = instance_create_depth(0, 0, -10, oFadeOut)
	fade_out_effect.alpha_step = 0.02
	fade_out_effect.end_function = __funTrainingEndFunction
}