if (keyboard_check_pressed(vk_anykey) and !self.goto_next_level) {
	self.goto_next_level = true

	var fade_out_effect = instance_create_depth(0, 0, -10, oFadeOut)
	fade_out_effect.alpha_step = 0.02
	fade_out_effect.end_function = room_goto_next
	global.is_training_completed = true
}