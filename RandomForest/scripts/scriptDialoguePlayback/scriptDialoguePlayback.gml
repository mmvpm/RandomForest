/// Initializes one monologue after its configured exploration delay.
function funBeginDialogue(lines, progress, typing_speed, end_function) {
	self.lines = lines
	self.progress = progress
	self.typing_speed = typing_speed
	self.end_function = end_function
	self.line_index = 0
	self.page_index = 0
	self.ready = true
	if (array_length(lines) == 0) {
		self.end_function()
		instance_destroy()
		return
	}
	funPrepareDialogueLine()
}

/// Measures each page once so partial text never changes line breaks.
function funPrepareDialogueLine() {
	var line = self.lines[self.line_index]
	if (variable_struct_exists(line, "reward") and line.reward) {
		global.black_room_context.reward_staged = true
		with (oPlayer) funPlayerRefreshAbilities()
	}
	self.speaker = variable_struct_exists(line, "speaker") ? line.speaker : "Голос"
	draw_set_font(global.dialogue_font_12)
	var text = funExpandDialogueText(line.text, self.progress)
	self.pages = funLayoutDialogue(funParseDialogueText(text), self.text_width,
		self.line_height, self.rows_per_page)
	self.page_index = 0
	self.revealed = 0
}

/// Reveals a page or dismisses a line; authored actions temporarily hide the panel.
function funAdvanceDialogue() {
	var count = array_length(self.pages[self.page_index].glyphs)
	if (self.revealed < count) {
		self.revealed = count
		return
	}
	if (self.page_index + 1 < array_length(self.pages)) {
		++self.page_index
		self.revealed = 0
		return
	}
	var line = self.lines[self.line_index]
	if (variable_struct_exists(line, "action")) {
		oBlackRoomController.pause_dialogue(self.line_index + 1, line.action)
		instance_destroy()
		return
	}
	if (self.line_index + 1 < array_length(self.lines)) {
		++self.line_index
		funPrepareDialogueLine()
		return
	}
	self.end_function()
	instance_destroy()
}
