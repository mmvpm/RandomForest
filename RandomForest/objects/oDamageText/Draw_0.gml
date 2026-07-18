/// @description Draw crisp damage text with a one-pixel outline.

draw_set_font(global.damage_font_10)
draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_set_alpha(1)

for (var outline_x = -1; outline_x <= 1; ++outline_x) {
	for (var outline_y = -1; outline_y <= 1; ++outline_y) {
		if (outline_x == 0 and outline_y == 0) {
			continue
		}
		draw_text_color(
			self.x + outline_x,
			self.y + outline_y,
			self.text,
			self.outline_color,
			self.outline_color,
			self.outline_color,
			self.outline_color,
			self.current_alpha
		)
	}
}

draw_text_color(
	self.x,
	self.y,
	self.text,
	self.text_color,
	self.text_color,
	self.text_color,
	self.text_color,
	self.current_alpha
)

draw_set_halign(fa_left)
draw_set_valign(fa_top)
draw_set_color(c_white)
draw_set_alpha(1)
