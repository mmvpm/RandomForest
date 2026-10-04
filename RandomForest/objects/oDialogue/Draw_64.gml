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
draw_sprite_stretched_ext(sBorder4, 0, self.panel_x, self.panel_y,
	self.panel_width, panel_height, make_color_rgb(140, 140, 140), 1)
draw_set_font(global.dialogue_font_12)
draw_set_halign(fa_left)
draw_set_valign(fa_top)
draw_set_color(c_white)
draw_text(text_x, self.panel_y + 12, self.speaker)

var count = array_length(page.glyphs)
for (var i = 0; i < floor(self.revealed); ++i) {
	var glyph = page.glyphs[i]
	draw_set_color(glyph.colour)
	draw_text(text_x + glyph.x, text_y + glyph.y, glyph.letter)
}

draw_set_halign(fa_right)
draw_set_color(make_color_rgb(140, 140, 140))
var hint = self.revealed < count ? "Enter: показать текст" : "Enter: дальше"
draw_text(self.panel_x + self.panel_width - self.padding,
	self.panel_y + panel_height - 24, hint)

draw_set_color(c_white)
draw_set_alpha(1)
draw_set_halign(fa_left)
draw_set_valign(fa_top)
