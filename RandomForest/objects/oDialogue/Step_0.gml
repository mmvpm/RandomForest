/// Types independently of movement; Space advances and never triggers a stomp.
if (!self.ready or (!self.input_locked and keyboard_check_pressed(global.key_pause))
	or (instance_exists(oPauseMenu) and oPauseMenu.paused)) {
	exit
}
if (self.complete_drawn) {
    self.end_function()
    instance_destroy()
    exit
}
funStepDialogueTyping()
if (self.input_locked) funStepAutomaticDialogue()
else if (keyboard_check_pressed(vk_space)) funAdvanceDialogue()
