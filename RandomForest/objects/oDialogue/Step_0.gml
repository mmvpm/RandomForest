/// Types independently of movement; Space advances and never triggers a stomp.
if (!self.ready or keyboard_check_pressed(global.key_pause)
	or (instance_exists(oPauseMenu) and oPauseMenu.paused)) {
	exit
}
var count = array_length(self.pages[self.page_index].glyphs)
self.revealed = min(count, self.revealed + self.typing_speed / 60)
if (keyboard_check_pressed(vk_space)) {
	funAdvanceDialogue()
}
