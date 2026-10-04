/// Closes help immediately; its destroy event restores the caller.
if ((keyboard_check_pressed(vk_anykey) or mouse_check_button_pressed(mb_any)) and !self.end_training) {
    self.end_training = true
    instance_destroy()
}
