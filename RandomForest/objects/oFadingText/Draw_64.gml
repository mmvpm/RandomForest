// set up font
draw_set_halign(fa_middle)
draw_set_valign(fa_middle)
draw_set_font(self.default_font_24)

// draw text
draw_text_transformed_color(self.x, self.y, self.text, self.text_scale, self.text_scale, 0, c_white, c_white, c_white, c_white, self.text_alpha_current)