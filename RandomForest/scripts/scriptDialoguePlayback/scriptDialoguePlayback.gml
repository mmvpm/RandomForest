/// Initializes one monologue after its configured exploration delay.
function funBeginDialogue(lines, progress, typing_speed, end_function) {
	self.lines = lines
	self.progress = progress
	self.typing_speed = typing_speed
	self.end_function = end_function
	self.line_index = 0
	self.page_index = 0
	self.input_locked = false
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
	self.speaker_colour = funDialogueSpeakerColour(self.speaker)
	draw_set_font(global.dialogue_font_12)
	var text = funExpandDialogueText(line.text, self.progress)
	self.pages = funLayoutDialogue(funParseDialogueText(text), self.text_width,
		self.line_height, self.rows_per_page)
	self.page_index = 0
	self.revealed = 0
	self.typing_frames = 0
	self.complete_drawn = false
	self.page_complete_drawn = false
	self.auto_frames = 0
}

/// Advances only fully typed pages; authored actions temporarily hide the panel.
function funAdvanceDialogue(automatic = false) {
	var line = self.lines[self.line_index]
	if (!automatic and (self.input_locked
		or (variable_struct_exists(line, "lock_input") and line.lock_input))) return
	var count = array_length(self.pages[self.page_index].glyphs)
	if (self.revealed < count) return
	if (self.page_index + 1 < array_length(self.pages)) {
		++self.page_index
		self.revealed = 0
		self.typing_frames = 0
		self.complete_drawn = false
		self.page_complete_drawn = false
		self.auto_frames = 0
		return
	}
	// Automatic completion waits for Draw to present the final punctuation.
	if (variable_struct_exists(line, "auto_finish") and line.auto_finish) return
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

/// Spends active frames on glyphs; ellipsis delays replace normal character time.
function funStepDialogueTyping() {
    var glyphs = self.pages[self.page_index].glyphs
    self.typing_frames++
    while (self.revealed < array_length(glyphs)) {
        var glyph = glyphs[self.revealed]
        var frames = glyph.delay_frames > 0 ? glyph.delay_frames : 60 / self.typing_speed
        if (self.typing_frames < frames) break
        self.typing_frames -= frames
        self.revealed++
    }
    if (self.revealed == array_length(glyphs)) self.typing_frames = 0
}

/// Advances the locked final sequence only after the fully drawn page's hold.
function funStepAutomaticDialogue() {
    if (!self.page_complete_drawn) return
    var line = self.lines[self.line_index]
    if (!variable_struct_exists(line, "auto_advance_seconds")) return;
    self.auto_frames++
    if (self.auto_frames >= 60 * line.auto_advance_seconds) funAdvanceDialogue(true)
}
