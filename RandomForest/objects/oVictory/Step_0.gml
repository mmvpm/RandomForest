var any_button_pressed = keyboard_check_pressed(vk_anykey) or mouse_check_button_pressed(mb_any)
if (any_button_pressed and self.goto_next_level_counter < 2) {
	self.goto_next_level_counter += 1
}

if (self.goto_next_level_counter == 2) {
	var fade_out_effect = instance_create_depth(0, 0, -10, oFadeOut)
	fade_out_effect.alpha_step = 0.02

	function __temp() {
		audio_stop_all()
		room_goto(rMenu)
	}
	fade_out_effect.end_function = __temp

	funSaveGameState()
}