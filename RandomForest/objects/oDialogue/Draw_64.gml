/// Draws a pixel-aligned panel above the play area with stable premeasured text.
if (!self.ready) {
	exit
}
var page = self.pages[self.page_index]
var rows = max(2, page.rows)
var panel_height = 64 + rows * self.line_height
var text_x = self.panel_x + self.padding
var text_y = self.panel_y + 34

gpu_set_tex_filter(false)
draw_set_alpha(1)
draw_set_color(c_white)
var presentation = funUiScenePresentation()
funDrawUiPanel(sBorder4, 0, self.panel_x, self.panel_y,
	self.panel_width, panel_height, presentation.palette.panel_muted, 1, presentation)
draw_set_font(global.dialogue_font_12)
draw_set_halign(fa_left)
draw_set_valign(fa_top)
draw_set_color(self.speaker_colour)
funDrawDialogueLabel(self.speaker, text_x, self.panel_y + 12)

for (var i = 0; i < floor(self.revealed); ++i) {
	var glyph = page.glyphs[i]
	draw_set_color(glyph.colour)
	draw_text(text_x + glyph.x, text_y + glyph.y, glyph.letter)
}

draw_set_halign(fa_right)
draw_set_color(presentation.palette.panel_muted)
var line = self.lines[self.line_index]
var hint = "Пробел: дальше"
funDrawDialogueLabel(hint, self.panel_x + self.panel_width - self.padding,
	self.panel_y + panel_height - 24, true)

draw_set_color(c_white)
draw_set_alpha(1)
draw_set_halign(fa_left)
draw_set_valign(fa_top)

// Signal completion only after the entire final page has actually been drawn.
if (variable_struct_exists(line, "auto_finish") and line.auto_finish
    and self.page_index == array_length(self.pages) - 1
    and self.revealed >= array_length(page.glyphs)) self.complete_drawn = true

// Lock controls only after the deletion message has been presented in full.
if (self.revealed >= array_length(page.glyphs)) {
    self.page_complete_drawn = true
    if (variable_struct_exists(line, "lock_input") and line.lock_input) self.input_locked = true
}
